#include <stdio.h>
#include <string.h>
#include <sys/select.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "esp_system.h"
#include "esp_heap_caps.h"
#include "Display_SPD2010.h"
#include "I2C_Driver.h"
#include "TCA9554PWR.h"
#include "PWR_Key.h"
#include "assets.h"
static lv_obj_t *picture;
static unsigned current=0;
static bool automatic=true,held=false;
static lv_timer_t *slideshow;
static const char *TAG="gallery";
static void refresh(void){
 lv_img_set_src(picture,&gallery_images[current]);
 ESP_LOGI(TAG,"SHOW %u/%u %s",current+1,GALLERY_COUNT,gallery_names[current]);
}
static void advance(int delta){current=(current+GALLERY_COUNT+delta)%GALLERY_COUNT;refresh();}
static void auto_tick(lv_timer_t *timer){if(automatic)advance(1);}
static void touch(lv_event_t *event){
 lv_event_code_t code=lv_event_get_code(event);
 if(code==LV_EVENT_PRESSED){held=false;ESP_LOGI(TAG,"TOUCH pressed");}
 if(code==LV_EVENT_LONG_PRESSED){held=true;automatic=!automatic;lv_timer_reset(slideshow);refresh();ESP_LOGI(TAG,"TOUCH hold auto=%d",automatic);}
 if(code==LV_EVENT_CLICKED&&!held){automatic=false;advance(1);ESP_LOGI(TAG,"TOUCH advance");}
}
static void command(const char *line){
 if(!strcmp(line,"NEXT"))advance(1);
 else if(!strcmp(line,"PREV"))advance(-1);
 else if(!strcmp(line,"PAUSE")){automatic=false;refresh();}
 else if(!strcmp(line,"AUTO")){automatic=true;lv_timer_reset(slideshow);refresh();}
 else if(!strcmp(line,"STATUS"))ESP_LOGI(TAG,"STATUS index=%u count=%u auto=%d free_heap=%lu",current,GALLERY_COUNT,automatic,(unsigned long)esp_get_free_heap_size());
}
void app_main(void){
 ESP_LOGI(TAG,"OpenDotlet sticker gallery v4 upright U-eyes boot");
 PWR_Init();I2C_Init();ESP_ERROR_CHECK(EXIO_Init());
 LCD_Init();Set_Backlight(65);LVGL_Init();gallery_assets_init();
 lv_obj_t *screen=lv_scr_act();lv_obj_set_style_bg_color(screen,lv_color_hex(0x000000),0);
 lv_obj_clear_flag(screen,LV_OBJ_FLAG_SCROLLABLE);lv_obj_add_event_cb(screen,touch,LV_EVENT_ALL,NULL);
 picture=lv_img_create(screen);lv_obj_align(picture,LV_ALIGN_CENTER,0,0);lv_obj_clear_flag(picture,LV_OBJ_FLAG_CLICKABLE);
 slideshow=lv_timer_create(auto_tick,7000,NULL);refresh();
 ESP_LOGI(TAG,"READY resolution=412x412 images=%u touch=SPD2010; tap next, hold auto/pause",GALLERY_COUNT);
 char line[32];unsigned used=0;int64_t last=0;
 while(1){
  lv_timer_handler();PWR_Loop();
  fd_set readfds;FD_ZERO(&readfds);FD_SET(0,&readfds);struct timeval tv={0,0};
  if(select(1,&readfds,NULL,NULL,&tv)>0){int c=getchar();if(c=='\n'||c=='\r'){line[used]=0;if(used)command(line);used=0;}else if(c>=32&&c<127){if(used<sizeof(line)-1)line[used++]=(char)c;else used=0;}}
  int64_t now=esp_timer_get_time();if(now-last>30000000){last=now;ESP_LOGI(TAG,"ALIVE index=%u heap=%lu",current,(unsigned long)esp_get_free_heap_size());}
  vTaskDelay(pdMS_TO_TICKS(10));
 }
}
