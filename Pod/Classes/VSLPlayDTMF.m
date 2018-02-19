//
//  VSLPlayDTMF.m
//  VialerSIPLib
//
//  Created by Redmer Loen on 2/16/18.
//

#import "VSLPlayDTMF.h"

#import "NSString+PJString.h"
#import <VialerPJSIP/pjsua.h>
#import "VSLLogging.h"

@implementation VSLPlayDTMF

+(void)playSoundWithFile:(NSString *)soundFile {
    pj_status_t status = [self play_sound_during_call:[soundFile pjString]];

    if (status == PJ_SUCCESS) {
        VSLLogDebug(@"Played sound file");
    }else {
        VSLLogDebug(@"Failed playing sound file");
    }
}

+ (pj_status_t) play_sound_during_call:(pj_str_t) sound_file {
    static pj_thread_desc a_thread_desc;
    static pj_thread_t *a_thread;
    if (!pj_thread_is_registered()) {
        pj_thread_register(NULL, a_thread_desc, &a_thread);
    }

    pjsua_player_id player_id;
    pj_status_t status;
    status = pjsua_player_create(&sound_file, 0, &player_id);
    if (status != PJ_SUCCESS) {
        return status;
    }

    pjmedia_port *player_media_port;

    status = pjsua_player_get_port(player_id, &player_media_port);
    if (status != PJ_SUCCESS)
    {
        return status;
    }

    pj_pool_t *pool = pjsua_pool_create("my_eof_data", 512, 512);
    struct pjsua_player_eof_data *eof_data = PJ_POOL_ZALLOC_T(pool, struct pjsua_player_eof_data);
    eof_data->pool = pool;
    eof_data->player_id = player_id;

    pjmedia_wav_player_set_eof_cb(player_media_port, eof_data, &on_pjsua_wav_file_end_callback);

    status = pjsua_conf_connect(pjsua_player_get_conf_port(player_id), 0);

    if (status != PJ_SUCCESS)
    {
        return status;
    }

    return status;
}

struct pjsua_player_eof_data
{
    pj_pool_t          *pool;
    pjsua_player_id player_id;
};

static PJ_DEF(pj_status_t) on_pjsua_wav_file_end_callback(pjmedia_port* media_port, void* args)
{
    pj_status_t status;

    struct pjsua_player_eof_data *eof_data = (struct pjsua_player_eof_data *)args;

    status = pjsua_player_destroy(eof_data->player_id);

    VSLLogError(@"End of WAV file, media port: %ld", media_port->port_data.ldata);

    if (status == PJ_SUCCESS)
    {
        return -1;// Here it is important to return a value other than PJ_SUCCESS
        //Check link below
    }

    return PJ_SUCCESS;
}

@end
