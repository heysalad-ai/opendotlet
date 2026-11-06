// OpenDotlet: Silicon Labs MG24 microphone + NeoKey, encrypted BLE clip transfer.
#include <SilabsMicrophoneAnalog.h>
#include "ezWS2812gpio.h"
constexpr uint32_t RATE=8000, MAX_SAMPLES=80000, PERIOD_US=125;
uint16_t samples[MAX_SAMPLES]; uint32_t micBuffer[1];
MicrophoneAnalog microphone(PC9,PC8); ezWS2812gpio pixel(1,D3);
uint16_t controlHandle=0,statusHandle=0,audioHandle=0;
volatile uint8_t connection=0xff;
volatile bool encrypted=false,statusSubscribed=false,audioSubscribed=false;
volatile bool enabled=false,cancelled=false,dirty=true;
volatile uint32_t hostAt=0;
volatile uint8_t pendingCommand=0;
uint8_t state=0,reason=0; uint16_t clipID=0,mtu=23;
uint32_t count=0,elapsed=0,checksum=0,maxLate=0,offset=0,transferAt=0;
bool keyLast=HIGH,stable=HIGH,mustRelease=true; uint32_t changedAt=0;
uint8_t advHandle=0xff;
void rgb(uint8_t r,uint8_t g,uint8_t b){noInterrupts();pixel.set_all(r,g,b,10);interrupts();}
void put16(uint8_t *p,uint16_t n){p[0]=n;p[1]=n>>8;}
void put32(uint8_t *p,uint32_t n){for(int i=0;i<4;i++)p[i]=n>>(8*i);}
bool live(){return connection!=0xff && encrypted && statusSubscribed && audioSubscribed;}
void status(){
  if(!statusHandle)return;
  uint8_t b[20]={1,state}; put16(b+2,clipID);put32(b+4,count);put32(b+8,elapsed);put32(b+12,checksum);
  put16(b+16,(uint16_t)min(maxLate,65535u));b[18]=reason;
  b[19]=(encrypted?1:0)|(digitalRead(PC8)==HIGH?2:0)|((statusSubscribed&&audioSubscribed)?4:0);
  sl_bt_gatt_server_write_attribute_value(statusHandle,0,sizeof(b),b);
  if(connection!=0xff && encrypted && statusSubscribed){
    sl_status_t sc=sl_bt_gatt_server_send_notification(connection,statusHandle,sizeof(b),b);
    if(sc!=SL_STATUS_OK){dirty=true;return;}
  }
  dirty=false;
}
void control(){
  uint8_t cmd=pendingCommand;pendingCommand=0;
  if(cmd==1&&state!=2&&state!=3&&live()){enabled=true;cancelled=false;hostAt=millis();state=1;dirty=true;}
  if(cmd==2){enabled=false;cancelled=true;dirty=true;}
}
void capture(){
  enabled=false;cancelled=false;state=2;reason=0;clipID++;count=elapsed=checksum=maxLate=offset=0;
  microphone.begin(micBuffer,1);rgb(0,255,0);dirty=true;status();delay(10);
  analogReadResolution(12);microphone.getSingleSample();
  uint32_t start=micros(),due=start,releaseAt=0;bool releasing=false;
  while(count<MAX_SAMPLES && micros()-start<10000000u){
    control();
    if(connection==0xff || !encrypted){reason=3;break;}
    if(cancelled){reason=2;break;}
    if(millis()-hostAt>5000){reason=4;break;}
    bool released=digitalRead(D2)==HIGH;
    if(released&&!releasing){releasing=true;releaseAt=millis();}
    if(!released)releasing=false;
    if(releasing&&millis()-releaseAt>=20){reason=0;break;}
    if((int32_t)(due-micros())>0)continue;
    maxLate=max(maxLate,micros()-due);
    samples[count++]=(uint16_t)microphone.getSingleSample();due+=PERIOD_US;
    if((int32_t)(micros()-due)>=(int32_t)PERIOD_US)due=micros()+PERIOD_US;
  }
  elapsed=micros()-start;
  if(count>=MAX_SAMPLES || elapsed>=10000000u)reason=1;
  // Single-shot ADC reads are complete. Avoid core 4.0.0 ADC DMA teardown.
  digitalWrite(PC8,LOW);
  if(reason>=2 || !live() || count==0){state=0;rgb(0,0,0);dirty=true;}
  else{
    checksum=2166136261u;const uint8_t *p=(const uint8_t*)samples;
    for(uint32_t i=0;i<count*2;i++)checksum=(checksum^p[i])*16777619u;
    state=3;transferAt=millis();rgb(0,0,255);dirty=true;
  }
  mustRelease=true;keyLast=stable=digitalRead(D2);changedAt=millis();
}
void transfer(){
  if(!live()||cancelled||millis()-transferAt>75000){state=0;rgb(0,0,0);dirty=true;return;}
  if(dirty){status();return;} // Metadata is queued before any audio.
  if(offset>=count*2){state=4;rgb(0,0,0);dirty=true;return;}
  uint8_t packet[187];uint32_t n=min((uint32_t)min((int)mtu-10,180),(count*2)-offset);
  packet[0]=0xa1;put16(packet+1,clipID);put32(packet+3,offset);
  memcpy(packet+7,((const uint8_t*)samples)+offset,n);
  sl_status_t sc=sl_bt_gatt_server_send_notification(connection,audioHandle,n+7,packet);
  if(sc==SL_STATUS_OK)offset+=n;
}
void advertise(){
  if(advHandle==0xff){app_assert_status(sl_bt_advertiser_create_set(&advHandle));
    app_assert_status(sl_bt_advertiser_set_timing(advHandle,160,160,0,0));}
  app_assert_status(sl_bt_legacy_advertiser_generate_data(advHandle,sl_bt_advertiser_general_discoverable));
  app_assert_status(sl_bt_legacy_advertiser_start(advHandle,sl_bt_advertiser_connectable_scannable));
}
void gatt(){
  uint16_t session,service,c;app_assert_status(sl_bt_gattdb_new_session(&session));
  uint8_t ga[]={0,0x18};app_assert_status(sl_bt_gattdb_add_service(session,sl_bt_gattdb_primary_service,0,2,ga,&service));
  sl_bt_uuid_16_t nameUUID={{0,0x2a}};const char *name="OpenDotlet Mic";
  app_assert_status(sl_bt_gattdb_add_uuid16_characteristic(session,service,SL_BT_GATTDB_CHARACTERISTIC_READ,0,0,nameUUID,sl_bt_gattdb_fixed_length_value,strlen(name),strlen(name),(const uint8_t*)name,&c));
  app_assert_status(sl_bt_gattdb_start_service(session,service));
  // 5F31A700-6D6C-4B7D-9F7C-0A2D6E010001, little endian on wire.
  uuid_128 uuid={{0x01,0x00,0x01,0x6e,0x2d,0x0a,0x7c,0x9f,0x7d,0x4b,0x6c,0x6d,0x00,0xa7,0x31,0x5f}};
  app_assert_status(sl_bt_gattdb_add_service(session,sl_bt_gattdb_primary_service,SL_BT_GATTDB_ADVERTISED_SERVICE,16,uuid.data,&service));
  uuid.data[12]=0x01;uint8_t zero=0;
  app_assert_status(sl_bt_gattdb_add_uuid128_characteristic(session,service,SL_BT_GATTDB_CHARACTERISTIC_WRITE,SL_BT_GATTDB_ENCRYPTED_WRITE,0,uuid,sl_bt_gattdb_fixed_length_value,1,1,&zero,&controlHandle));
  uuid.data[12]=0x02;uint8_t initial[20]={1};
  app_assert_status(sl_bt_gattdb_add_uuid128_characteristic(session,service,SL_BT_GATTDB_CHARACTERISTIC_READ|SL_BT_GATTDB_CHARACTERISTIC_NOTIFY,SL_BT_GATTDB_ENCRYPTED_READ|SL_BT_GATTDB_ENCRYPTED_NOTIFY,0,uuid,sl_bt_gattdb_fixed_length_value,20,20,initial,&statusHandle));
  uuid.data[12]=0x03;
  app_assert_status(sl_bt_gattdb_add_uuid128_characteristic(session,service,SL_BT_GATTDB_CHARACTERISTIC_NOTIFY,SL_BT_GATTDB_ENCRYPTED_NOTIFY,0,uuid,sl_bt_gattdb_variable_length_value,187,0,nullptr,&audioHandle));
  app_assert_status(sl_bt_gattdb_start_service(session,service));app_assert_status(sl_bt_gattdb_commit(session));
}
void setup(){
  Serial.begin(115200);pinMode(D2,INPUT_PULLUP);pinMode(PC8,OUTPUT);digitalWrite(PC8,LOW);
  CoreDebug->DEMCR|=CoreDebug_DEMCR_TRCENA_Msk;DWT->CTRL|=DWT_CTRL_CYCCNTENA_Msk;__DSB();__ISB();
  pixel.begin();rgb(0,0,0);keyLast=stable=digitalRead(D2);mustRelease=stable==LOW;
}
void loop(){
  control();
  if(state==3){transfer();delay(1);return;}
  if(connection==0xff||!encrypted||cancelled){enabled=false;if(state!=2){state=0;rgb(0,0,0);}}
  if(enabled&&millis()-hostAt>5000){enabled=false;state=0;dirty=true;}
  if(dirty)status();
  bool raw=digitalRead(D2);uint32_t now=millis();
  if(raw!=keyLast){keyLast=raw;changedAt=now;}
  if(raw!=stable&&now-changedAt>=20){stable=raw;if(stable==HIGH)mustRelease=false;else if(enabled&&!mustRelease&&live())capture();}
  delay(1);
}
void sl_bt_on_event(sl_bt_msg_t *evt){
  switch(SL_BT_MSG_ID(evt->header)){
    case sl_bt_evt_system_boot_id:{uint16_t negotiated;app_assert_status(sl_bt_gatt_server_set_max_mtu(247,&negotiated));}gatt();app_assert_status(sl_bt_sm_configure(0,sl_bt_sm_io_capability_noinputnooutput));app_assert_status(sl_bt_sm_set_bondable_mode(1));advertise();Serial.println("DOTLET_BLE_1 READY");break;
    case sl_bt_evt_connection_opened_id:connection=evt->data.evt_connection_opened.connection;encrypted=false;enabled=false;cancelled=false;dirty=true;sl_bt_connection_set_parameters(connection,24,40,0,400,0,0xffff);sl_bt_sm_increase_security(connection);break;
    case sl_bt_evt_connection_parameters_id:encrypted=evt->data.evt_connection_parameters.security_mode>0;dirty=true;break;
    case sl_bt_evt_connection_closed_id:connection=0xff;encrypted=false;enabled=false;cancelled=true;statusSubscribed=audioSubscribed=false;mtu=23;dirty=true;advertise();break;
    case sl_bt_evt_gatt_mtu_exchanged_id:mtu=evt->data.evt_gatt_mtu_exchanged.mtu;break;
    case sl_bt_evt_sm_bonding_failed_id:sl_bt_connection_close(evt->data.evt_sm_bonding_failed.connection);break;
    case sl_bt_evt_gatt_server_characteristic_status_id:{auto &e=evt->data.evt_gatt_server_characteristic_status;
      if(e.status_flags==sl_bt_gatt_server_client_config){if(e.characteristic==statusHandle)statusSubscribed=e.client_config_flags==sl_bt_gatt_server_notification;if(e.characteristic==audioHandle)audioSubscribed=e.client_config_flags==sl_bt_gatt_server_notification;dirty=true;}break;}
    case sl_bt_evt_gatt_server_attribute_value_id:{auto &e=evt->data.evt_gatt_server_attribute_value;
      if(e.attribute==controlHandle&&e.value.len==1&&encrypted){uint8_t cmd=e.value.data[0];
        if(cmd==3)hostAt=millis();else pendingCommand=cmd;}
      break;}
  }
}
#ifndef ARDUINO_SILABS_STACK_BLE_SILABS
#error "Select BLE (Silabs) protocol stack"
#endif
