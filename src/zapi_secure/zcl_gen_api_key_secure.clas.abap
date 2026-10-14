CLASS zcl_gen_api_key_secure DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_api,
        fecha    TYPE sy-datum,
        bukrs    TYPE bukrs,
        descrip  TYPE zdescr,
        servicio TYPE zservicio,
        ifecha   TYPE i,
        api_key  TYPE zapi_key,
      END OF ty_api,

      BEGIN OF ty_secure,
        key       TYPE guid_32,
        iv        TYPE guid_16,
        plain     TYPE string,
        encrypted TYPE xstring,
        decrypted TYPE string,
      END OF ty_secure,

      BEGIN OF ty_aes_secure,
        key        TYPE xstring,
        iv         TYPE xstring,
        guid_key   TYPE guid_32,
        guid_iv    TYPE guid_16,
        plain      TYPE string,
        plain_xstr TYPE xstring,
        encrypted  TYPE xstring,
        decryptedx TYPE xstring,
        decrypted  TYPE string,
        clave      TYPE string,
        result     TYPE string,
      END OF ty_aes_secure.

    DATA:
      ms_api        TYPE ty_api READ-ONLY,
      ms_secure     TYPE ty_secure,
      ms_aes_secure TYPE ty_aes_secure.
*      mv_api_key  TYPE zapi_key READ-ONLY,
*      mv_bukrs    TYPE bukrs READ-ONLY,
*      mv_descrip  TYPE zdescr READ-ONLY,
*      mv_servicio TYPE zservicio READ-ONLY.

    INTERFACES if_oo_adt_classrun.

    METHODS:
      constructor
        IMPORTING
*          iv_api_key  TYPE zapi_key
          iv_fecha    TYPE sy-datum DEFAULT sy-datum
          iv_bukrs    TYPE bukrs
          iv_descrip  TYPE zdescr
          iv_servicio TYPE zservicio,

      "! @parameter iv_pass_key |
      "! @parameter rv_encripted |
      "! @raising cx_sec_sxml_encrypt_error |
      decrypt
        IMPORTING iv_pass_key         TYPE string
                  iv_encrypted        TYPE xstring
                  iv_algorithm        TYPE string OPTIONAL
        EXPORTING ev_return           TYPE abap_bool
        RETURNING VALUE(rv_decripted) TYPE string
        RAISING   cx_sec_sxml_encrypt_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
    DATA:
      mv_to_be_encrypted TYPE xstring.

    METHODS:
      create_api
        RETURNING
          VALUE(rv_encripted) TYPE xstring,

      create_api1
        RETURNING
          VALUE(rv_encripted) TYPE xstring,

      "! @parameter iv_pass_key |
      "! @parameter rv_encripted |
      "! @raising cx_sec_sxml_encrypt_error |
      encrypt
        IMPORTING iv_pass_key         TYPE string
        RETURNING VALUE(rv_encripted) TYPE xstring
        RAISING   cx_sec_sxml_encrypt_error.

ENDCLASS.

CLASS zcl_gen_api_key_secure IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.
    cl_demo_output=>display( 'Prueba' ).
  ENDMETHOD.

  METHOD constructor.
    ms_api = VALUE #(
        fecha = iv_fecha
        bukrs = iv_bukrs
        descrip = iv_descrip
        servicio = iv_servicio
        ifecha = iv_fecha ).
*
    mv_to_be_encrypted = cl_abap_codepage=>convert_to(
                            source = |{ ms_api-ifecha }-{ ms_api-bukrs }-{ ms_api-descrip }-{ ms_api-servicio }|
                            codepage = 'UTF-8').


*
*    ms_aes_secure = VALUE #( key = mv_to_be_encrypted
*                             iv  = mv_to_be_encrypted
*                             plain = |{ ms_api-bukrs }-{ ms_api-descrip }-{ ms_api-servicio }|
*                             clave = ms_api-bukrs ).
*
*    cl_demo_output=>display( mv_to_be_encrypted ).
*
**    create_api( ).
*
*    ms_aes_secure-encrypted = encrypt( iv_pass_key = ms_api-bukrs ).
*
*    ms_aes_secure-decrypted = decrypt(
*                            EXPORTING
*                              iv_pass_key               = ms_api-bukrs
*                              iv_encrypted              = ms_aes_secure-encrypted
**                              iv_algorithm              = iv_algorithm
**                            IMPORTING
**                              ev_return                 = ev_return
*                          ).
**                            CATCH cx_sec_sxml_encrypt_error.    " .
*
*    cl_demo_output=>display( ms_aes_secure ).

*  CATCH cx_sec_sxml_encrypt_error.    "
    create_api( ).
  ENDMETHOD.

  METHOD create_api.
    DATA:
      lv_key       TYPE guid_32,
      lv_iv        TYPE guid_16,
      lv_api_key   TYPE string,
      lv_encrypted TYPE xstring.

    DATA: ls_secure TYPE ty_secure.

    TRY.
        " 1. Generar UUID como API Key 32
        CALL FUNCTION 'GUID_CREATE'
          IMPORTING
            ev_guid_32 = ms_aes_secure-guid_key.

*        CALL FUNCTION 'GUID_CREATE'
*          IMPORTING
*            ev_guid_32 = ls_secure-key.

        " 1. Generar UUID como API Key IV
        CALL FUNCTION 'GUID_CREATE'
          IMPORTING
            ev_guid_16 = ms_aes_secure-guid_iv.

*        CALL FUNCTION 'GUID_CREATE'
*          IMPORTING
*            ev_guid_16 = ls_secure-iv.

      CATCH cx_root INTO DATA(lx_rand).
        WRITE: / 'Error generando clave o IV:', lx_rand->get_text( ).
        EXIT.
    ENDTRY.

    ms_secure = VALUE #( key = ms_aes_secure-key
                         iv  = ms_aes_secure-iv
                         plain = |{ ms_api-bukrs }-{ ms_api-descrip }-{ ms_api-servicio }| ).

    ls_secure-plain = |{ ms_api-bukrs }-{ ms_api-descrip }-{ ms_api-servicio }|.

    "------------------------------------------------------------
    " 3. Cifrar usando CL_SEC_SXML_WRITER
*    "------------------------------------------------------------
    TRY.

*        DATA(lo_writer1) = cl_sec_sxml_writer=>create(
*                          sxml_writer     = sxml_writer
*                      attribute       = attribute
*                      namespace       = namespace
*                      digest          = digest ).
*

*        DATA(lo_writer) = cl_sec_sxml_writer=>create(
*                      sxml_writer     = if_sec_sxml_writer=>co_type_encrypted
**                      attribute       = attribute
**                      namespace       = namespace
**                      digest          = digest
*                          ).

*        DATA(lo_writer) = cl_sec_sxml_writer=>create(
*            type      = if_sec_sxml_writer=>co_type_encrypted
*            algorithm = if_sec_sxml_writer=>co_aes256_cbc
*            key       = lv_key
*            iv        = lv_iv
*        ).
*
*        lo_writer->write( lv_plain ).
*        lv_encrypted = lo_writer->get_output( ).
*
*      CATCH cx_sec_sxml INTO DATA(lx_enc).
*        WRITE: / 'Error cifrando:', lx_enc->get_text( ).
*        EXIT.
    ENDTRY.

*    ms_secure-plain = |{ ms_api-bukrs }-{ ms_api-descrip }-{ ms_api-servicio }|.
*
*    cl_demo_output=>display(  ms_aes_secure-key ).
*    cl_demo_output=>display( ms_aes_secure-iv ).

    cl_demo_output=>display( ms_secure ).
    cl_demo_output=>display( ms_api ).

  ENDMETHOD.

  METHOD create_api1.
    DATA:
      lv_api_guid  TYPE guid_32,
      lv_api_key   TYPE string,
      lv_encrypted TYPE xstring.

    DATA: ls_secure TYPE ty_secure.

    TRY.
        " 1. Generar UUID como API Key
        CALL FUNCTION 'GUID_CREATE'
          IMPORTING
            ev_guid_32 = lv_api_guid.

        lv_api_key = lv_api_guid.
        " 2. Convertir a XSTRING

*        lv_api_key = |{ ms_api-bukrs }-{ ms_api-descrip }-{ ms_api-servicio }|.
        DATA(lv_api_key_x) = cl_abap_codepage=>convert_to( source = lv_api_key ).

      CATCH cx_root INTO DATA(lx_aes).
        WRITE: / 'Error en encriptación:', lx_aes->get_text( ).
        EXIT.
    ENDTRY.

    cl_demo_output=>display( lv_api_key ).
    cl_demo_output=>display( lv_api_key_x ).

    TRY.
        " --- Prepare Key and IV ---
        " AES-128 → 16 bytes key, IV always 16 bytes
*        DATA(lv_key) = cl_abap_random=>seed( ).
*        DATA(lv_iv)  = cl_abap_random=>seed( ).
*        data(lv_key) = cl_abap_random=>seed( seed = 'myseed' length = 16 ).
*        DATA(lv_iv)  = cl_abap_random=>seed( seed = 'ivseed' length = 16 ).
        CALL FUNCTION 'GUID_CREATE'
          IMPORTING
            ev_guid_32 = ls_secure-key.

        " 1. Generar UUID como API Key IV
        CALL FUNCTION 'GUID_CREATE'
          IMPORTING
            ev_guid_16 = ms_aes_secure-iv.

        CALL FUNCTION 'GUID_CREATE'
          IMPORTING
            ev_guid_16 = ls_secure-iv.

        " --- Encrypt ---
*        DATA(lo_writer) = cl_sec_sxml_writer=>create( ).
*        DATA(lo_writer) = cl_sec_sxml_writer=>create(
*            sxml_writer =   cl_sxml_writer=>if_sxml_writer "if_sxml=>co_xt_binary " if_sec_sxml_writer=>co_xt_aes128_cbc
**            type = if_sec_sxml_writer=>co_xt_aes128_cbc
*            key  = lv_key
*            iv   = lv_iv ).



*        lo_writer->write( cl_abap_codepage=>convert_to( lv_plaintext ) ).
*        lv_ciphertext = lo_writer->get_output( ).
*
*        WRITE: / 'Ciphertext (hex):', lv_ciphertext.

      CATCH cx_root INTO DATA(lx_err).
        WRITE: / 'Error:', lx_err->get_text( ).
    ENDTRY.

    TRY.
        cl_sec_sxml_writer=>encrypt(
          EXPORTING
            plaintext  = lv_api_key_x
            key        = CONV #( lv_api_key )
            algorithm  = cl_sec_sxml_writer=>co_aes256_algorithm
          IMPORTING
            ciphertext = rv_encripted ).
      CATCH cx_sec_sxml_encrypt_error.
        RAISE EXCEPTION TYPE cx_sec_sxml_encrypt_error.
    ENDTRY.

    cl_demo_output=>display( lv_api_key ).
  ENDMETHOD.

  METHOD encrypt.
    TRY.
        cl_sec_sxml_writer=>encrypt(
          EXPORTING
            plaintext  = mv_to_be_encrypted
            key        = CONV #( iv_pass_key )
            algorithm  = cl_sec_sxml_writer=>co_aes256_algorithm
          IMPORTING
            ciphertext = rv_encripted ).
      CATCH cx_sec_sxml_encrypt_error.
        RAISE EXCEPTION TYPE cx_sec_sxml_encrypt_error.
    ENDTRY.

*    mv_encripted = rv_encripted.

    cl_demo_output=>display( rv_encripted ).

  ENDMETHOD.

  METHOD decrypt.

    IF iv_algorithm IS INITIAL.
      DATA(lv_algorithm) = cl_sec_sxml_writer=>co_aes256_algorithm.
    ELSE.
      lv_algorithm = iv_algorithm.
    ENDIF.

*    " Convert string to xstring
*    DATA lv_key TYPE xstring.
*
*    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
*      EXPORTING
*        text   = iv_pass_key "'MySecret'
*      IMPORTING
*        buffer = lv_key.

    TRY.
        cl_sec_sxml_writer=>decrypt(
          EXPORTING
            ciphertext = iv_encrypted
            key        = CONV #( iv_pass_key )
            algorithm  = lv_algorithm
          IMPORTING
            plaintext  = DATA(lv_decrypted) ).

        rv_decripted = cl_abap_codepage=>convert_from(
                   source                        = lv_decrypted
*                   codepage                      = codepage
*                   endian                        = endian
*                   replacement                   = replacement
*                   ignore_cerr                   = ignore_cerr
               ).

*        rv_decripted = cl_abap_complexdescr

*        ms_aes_secure-decrypted = rv_decripted.
*                 CATCH cx_parameter_invalid_range.  "
*                 CATCH cx_sy_codepage_converter_init.  "
*                 CATCH cx_sy_conversion_codepage.  "
*                 CATCH cx_parameter_invalid_type.  "

*        rv_decripted = cl_abap_conv_in_ce=>create( )->convert( ms_aes_secure-decrypted ).
*        rv_decripted = cl_abap_codepage=>convert_from(
*                   source                        = ms_aes_secure-decrypted
**                   codepage                      = codepage
**                   endian                        = endian
**                   replacement                   = replacement
**                   ignore_cerr                   = ignore_cerr
*               ).
*                 CATCH cx_parameter_invalid_range.  "
*                 CATCH cx_sy_codepage_converter_init.  "
*                 CATCH cx_sy_conversion_codepage.  "
*                 CATCH cx_parameter_invalid_type.  "
*        conv_in_ce=>create( )->convert( lv_decrypted ).
*        convert_to( iv_string )
      CATCH cx_sec_sxml_encrypt_error.
        RAISE EXCEPTION TYPE cx_sec_sxml_encrypt_error.
    ENDTRY.

    cl_demo_output=>display( rv_decripted ).
*    DATA(lv_valid) = valid_pass_key( rv_decripted ).
*
*    IF valid_pass_key( rv_decripted ) EQ abap_false.
*      RETURN.
*    ENDIF.
*
*    CHECK lv_valid EQ abap_true.
*
*    ev_return = abap_true.

  ENDMETHOD.

ENDCLASS.
