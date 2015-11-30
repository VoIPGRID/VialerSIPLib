/*
 * This file contains several sample settings especially for Windows
 * Mobile and Symbian targets. You can include this file in your
 * <pj/config_site.h> file.
 *
 * The Windows Mobile and Symbian settings will be activated
 * automatically if you include this file.
 *
 * In addition, you may specify one of these macros (before including
 * this file) to activate additional settings:
 *
 * #define PJ_CONFIG_NOKIA_APS_DIRECT
 *   Use this macro to activate the APS-Direct feature. Please see
 *   http://trac.pjsip.org/repos/wiki/Nokia_APS_VAS_Direct for more 
 *   info.
 *
 * #define PJ_CONFIG_WIN32_WMME_DIRECT
 *   Configuration to activate "APS-Direct" media mode on Windows or
 *   Windows Mobile, useful for testing purposes only.
 */

/*
 * PJLIB settings.
 */

/* Both armv6 and armv7 has FP hardware support.
 * See https://trac.pjsip.org/repos/ticket/1589 for more info
 */
#define PJ_HAS_FLOATING_POINT		1

/*
 * PJMEDIA settings
 */

/* We have our own native CoreAudio backend */
#define PJMEDIA_AUDIO_DEV_HAS_PORTAUDIO	0
#define PJMEDIA_AUDIO_DEV_HAS_WMME		0
#define PJMEDIA_AUDIO_DEV_HAS_COREAUDIO	1

/* The CoreAudio backend has built-in echo canceller! */
#define PJMEDIA_HAS_SPEEX_AEC    0

/* Disable some codecs */
#define PJMEDIA_HAS_L16_CODEC		0
#define PJMEDIA_HAS_G722_CODEC		1
#define PJMEDIA_HAS_G711_CODEC      1


/* Use the built-in CoreAudio's iLBC codec (yay!) */
#define PJMEDIA_HAS_ILBC_CODEC		1
#define PJMEDIA_ILBC_CODEC_USE_COREAUDIO	1

/* Fine tune Speex's default settings for best performance/quality */
#define PJMEDIA_CODEC_SPEEX_DEFAULT_QUALITY	5

/*
 * PJSIP settings.
 */

/* Increase allowable packet size, just in case */
//#define PJSIP_MAX_PKT_LEN			2000

/*
 * PJSUA settings.
 */

/* Default codec quality, previously was set to 5, however it is now
 * set to 4 to make sure pjsua instantiates resampler with small filter.
 */
#define PJSUA_DEFAULT_CODEC_QUALITY		4

/* Set maximum number of dialog/transaction/calls to minimum */
#define PJSIP_MAX_TSX_COUNT 		31
#define PJSIP_MAX_DIALOG_COUNT 		31
#define PJSUA_MAX_CALLS			4

/* Other pjsua settings */
#define PJSUA_MAX_ACC			4
#define PJSUA_MAX_PLAYERS			4
#define PJSUA_MAX_RECORDERS			4
#define PJSUA_MAX_CONF_PORTS		(PJSUA_MAX_CALLS+2*PJSUA_MAX_PLAYERS)
#define PJSUA_MAX_BUDDIES			32
