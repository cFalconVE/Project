*&---------------------------------------------------------------------*
*& Report  zgen_api_key_secure
*&---------------------------------------------------------------------*
*  FECHA DE CREACION: 30.06.2026
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : Program
*  ORDEN          : DR3K981742
*  Solicitud      : REQ-1354
*&---------------------------------------------------------------------*
*   Descripción
*   Generar y guardar API Key encriptada
*
*&---------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
* Fecha       Caso    User    Orden       Descripción
*
*
*&---------------------------------------------------------------------*
REPORT zgen_api_key_secure.

DATA: lv_api_key     TYPE string,
      lv_api_key_enc TYPE xstring,
      lv_key_aes     TYPE xstring VALUE '1234567890ABCDEF1234567890ABCDEF', " 32 bytes para AES-256
      lv_iv          TYPE xstring VALUE 'ABCDEF1234567890', " 16 bytes IV
      lo_cipher      TYPE REF TO cl_abap_message_digest.

" 1. Generar UUID como API Key
CALL FUNCTION 'GUID_CREATE'
  IMPORTING
    ev_guid_32 = lv_api_key.

" 2. Convertir a XSTRING
DATA(lv_api_key_x) = cl_abap_codepage=>convert_to( source = lv_api_key ).

" 3. Encriptar con AES CBC
*TRY.
**    DATA(lo_aes) = cl_abap_aes=>create( iv_key = lv_key_aes iv_mode = 'CBC' iv_iv = lv_iv ).
*    lv_api_key_enc = lo_aes->encrypt( lv_api_key_x ).
*  CATCH cx_abap_aes INTO DATA(lx_aes).
*    WRITE: / 'Error en encriptación:', lx_aes->get_text( ).
*    EXIT.
*ENDTRY.

" 4. Insertar en tabla con fecha de expiración (30 días)
*INSERT zapi_keys_sec values value #(
*  api_key_enc = lv_api_key_enc
*  descripcion = 'Clave segura cliente X'
*  fecha_alta  = sy-datum
*  fecha_expira = sy-datum + 30
*).

IF sy-subrc = 0.
  WRITE: / 'API Key generada (guárdala antes de cifrar):', lv_api_key.
ELSE.
  WRITE: / 'Error insertando API Key'.
ENDIF.
