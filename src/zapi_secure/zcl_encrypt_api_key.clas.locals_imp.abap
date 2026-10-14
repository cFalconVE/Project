CLASS lcl_encryt_key DEFINITION.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ty_api,
        fecha     TYPE sy-datum,
        hora      TYPE sy-uzeit,
        bukrs     TYPE bukrs,
        descrip   TYPE zdescr,
        servicio  TYPE zservicio,
        host      TYPE zdominios,
        ip        TYPE zhost_ip,
        fecha_exp TYPE zfecha_expira,
      END OF ty_api,

      BEGIN OF ty_aes_secure,
*        ifecha     TYPE i,
        key        TYPE xstring,
        iv         TYPE xstring,

*        guid_key   TYPE guid_32,
*        guid_iv    TYPE guid_16,

        plain_txt  TYPE string,
        plain_xstr TYPE xstring,
        cipher     TYPE xstring,

*        encrypted  TYPE xstring,
        decryptedx TYPE xstring,
        decrypted  TYPE string,
      END OF ty_aes_secure,

      BEGIN OF ty_valid,
        bukrs    TYPE bukrs,
        servicio TYPE zservicio,
        key      TYPE xstring,
        host     TYPE zdominios,
        ip       TYPE zhost_ip,
      END OF ty_valid,

*      BEGIN OF ty_valid_secure,
*        bukrs TYPE bukrs,
*        key   TYPE xstring,
*        host  TYPE zdominios,
*        ip    TYPE zhost_ip,
*      END OF ty_valid_secure,

      BEGIN OF ty_valid_secure,
        bukrs       TYPE bukrs,
        key         TYPE xstring,
        fecha       TYPE sy-datum,
        hora        TYPE sy-uzeit,
*        plain_txt  TYPE string,
*        plain_xstr TYPE xstring,
        descripcion TYPE string,
        cipher      TYPE xstring,
        fecha_alta  TYPE zfecha_alta,
        fecha_exp   TYPE zfecha_expira,
        decryptedx  TYPE xstring,
      END OF ty_valid_secure.

    METHODS:
      "!
      "! @parameter is_api |
      "! @parameter ev_api_key |
      "! @parameter rv_return |
      create_api_key
        IMPORTING
          is_api           TYPE ty_api
        EXPORTING
          ev_api_key       TYPE xstring " sysuuid_x16
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      "!
      "! @parameter is_check |
      "! @parameter rv_return |
      check_api_key
        IMPORTING
          !is_check        TYPE ty_valid
        RETURNING
          VALUE(rv_return) TYPE abap_bool.

  PROTECTED SECTION.

  PRIVATE SECTION.

    METHODS:
      aes_encryp
        RETURNING
          VALUE(rv_return) TYPE sysuuid_x16,

      "!
      save_api
        IMPORTING
          is_api           TYPE ty_api
          is_aes_sec       TYPE ty_aes_secure
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      get_api
        IMPORTING
          is_api           TYPE ty_valid
        EXPORTING
          es_api_sec       TYPE ty_valid_secure
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      decrypt
        IMPORTING
          is_valid         TYPE ty_valid
        CHANGING
          es_valid         TYPE ty_valid_secure
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      commit_work.

ENDCLASS.

CLASS lcl_encryt_key IMPLEMENTATION.

  METHOD aes_encryp.

    TRY.
        rv_return = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error INTO DATA(cx).
    ENDTRY.

  ENDMETHOD.

  METHOD create_api_key.
    DATA:
      ls_aes_sec TYPE ty_aes_secure,
      lv_fecha   TYPE i,
      lv_hora    TYPE i.

    lv_fecha = is_api-fecha.
    lv_hora = is_api-hora.

    ls_aes_sec = VALUE #(
        plain_txt  = |{ is_api-bukrs }-{ lv_fecha }-{ lv_hora }-{ is_api-servicio }-{ is_api-descrip }|
        key        = aes_encryp( )
        iv         = aes_encryp( ) ).

*    ls_aes_sec-plain_xstr = cl_abap_codepage=>convert_to(
*                                source = ls_aes_sec-plain_txt
*                                codepage = 'UTF-8').

    TRY.
        ls_aes_sec-plain_xstr = cl_abap_hmac=>string_to_xstring( ls_aes_sec-plain_txt ).
      CATCH  cx_abap_message_digest INTO DATA(cx_digest).
    ENDTRY.

*    " 1. Generar UUID como API Key IV
*    CALL FUNCTION 'GUID_CREATE'
*      IMPORTING
*        ev_guid_16 = ls_aes_sec-guid_iv.

*--------------------------------------------------------------------*
* encrypt
*--------------------------------------------------------------------*
*    CALL METHOD cl_sec_sxml_writer=>encrypt
*      EXPORTING
*        plaintext  = ls_aes_sec-plain_xstr
*        key        = ls_aes_sec-key
*        algorithm  = cl_sec_sxml_writer=>co_aes256_algorithm_pem
*      IMPORTING
*        ciphertext = ls_aes_sec-cipher.

    CALL METHOD cl_sec_sxml_writer=>encrypt_iv(
      EXPORTING
        plaintext  = ls_aes_sec-plain_xstr
        key        = ls_aes_sec-key
        iv         = ls_aes_sec-iv
        algorithm  = cl_sec_sxml_writer=>co_aes128_algorithm "co_aes256_algorithm_pem
      IMPORTING
        ciphertext = ls_aes_sec-cipher ).

    CHECK sy-subrc EQ 0.

    cl_sec_sxml_writer=>check_encryption( ).

    ev_api_key = ls_aes_sec-key.

    rv_return = save_api(
       EXPORTING
         is_api     = is_api
         is_aes_sec = ls_aes_sec ).

  ENDMETHOD.

  METHOD save_api.
    DATA:
      ls_apik TYPE zap_host_apik,
      ls_apip TYPE zap_host_apip.

    TRY.
*        plain_txt  = |{ is_api-bukrs }-{ is_api-ifecha }-{ is_api-servicio }-{ is_api-descrip }|
        ls_apik = VALUE #(
            uuid = cl_system_uuid=>create_uuid_x16_static( )
            bukrs = is_api-bukrs
            valor = is_api-fecha
            servicio = is_api-servicio
            descripcion = is_api-descrip
            dominio = is_api-host
            host_ip = is_api-ip
            activo = abap_true
            ernam = sy-uname
            erdat = is_api-fecha
            erzet = is_api-hora ).

        " Insertar en tabla maestro

        INSERT zap_host_apik FROM ls_apik.

        CHECK sy-subrc EQ 0.

        ls_apip = VALUE #(
          uuid_k = ls_apik-uuid
          uuid_p = cl_system_uuid=>create_uuid_x16_static( )
          api_key = is_aes_sec-key
          cipher = is_aes_sec-cipher
          fecha_alta = sy-datum
          fecha_expira = is_api-fecha_exp
          ernam = ls_apik-ernam
          erdat = ls_apik-erdat
          erzet = ls_apik-erzet ).

        INSERT zap_host_apip FROM ls_apip.

      CATCH cx_uuid_error INTO DATA(lx_uuid).
        MESSAGE lx_uuid->get_text( ) TYPE 'E'.
    ENDTRY.

    CHECK sy-subrc EQ 0.

    commit_work( ).

    rv_return = abap_true.

  ENDMETHOD.

  METHOD commit_work.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

  METHOD check_api_key.
    DATA ls_valid_api TYPE ty_valid_secure.

    get_api(
      EXPORTING
        is_api     = is_check
      IMPORTING
        es_api_sec = ls_valid_api
      RECEIVING
        rv_return  = rv_return  ).

    CHECK rv_return EQ abap_true.

    decrypt(
      EXPORTING
        is_valid  = is_check
      CHANGING
        es_valid = ls_valid_api
      RECEIVING
        rv_return = rv_return ).

    CHECK rv_return EQ abap_true.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD decrypt.
    DATA:
      lv_decrypted TYPE string,
      lv_plain_txt TYPE string,
      lv_check     TYPE string,
      lv_fecha     TYPE i,
      lv_hora      TYPE i.

    lv_fecha = es_valid-fecha.
    lv_hora = es_valid-hora.

    lv_check = |{ es_valid-bukrs }-{ lv_fecha }-{ lv_hora }-{ is_valid-servicio }-{ es_valid-descripcion }|.

    TRY.
        cl_sec_sxml_writer=>decrypt(
          EXPORTING
             ciphertext = es_valid-cipher
             key        = es_valid-key " l_key_x
             algorithm  = cl_sec_sxml_writer=>co_aes128_algorithm "co_aes256_algorithm_pem
          IMPORTING
             plaintext  = es_valid-decryptedx ).

*        cl_sec_sxml_writer=>decrypt(
*          EXPORTING
*             ciphertext = '1BA3E36AA7D3047AE93F64CCC5B5504CEB30758EFEE3CBFA53DF5FF7C479B418FA81F9A7813A8A187AF51A0EBB138D70'
*             key =        '005056ABA0061FD1A9C69E04B142A000' " l_key_x
*             algorithm =  cl_sec_sxml_writer=>co_aes128_algorithm
*          IMPORTING
*            plaintext = es_valid-decryptedx ).

      CATCH cx_sec_sxml_encrypt_error.
        RAISE EXCEPTION TYPE cx_sec_sxml_encrypt_error.
    ENDTRY.

    " convert xstring to string for output
    cl_abap_conv_in_ce=>create( input = es_valid-decryptedx )->read( IMPORTING data = lv_decrypted ).

*    " output secret message
*    IF es_valid-plain_txt EQ es_valid-plain_txt.
**      WRITE es_valid-plain_txt.
*    ENDIF.

    rv_return = COND abap_bool(
        WHEN lv_check EQ lv_decrypted THEN abap_true
        ELSE abap_false ).

*    CHECK lv_check EQ lv_decrypted.

*    rv_return = abap_true.
  ENDMETHOD.

  METHOD get_api.

    SELECT bukrs, servicio, fecha, hora, dato, descripcion, dominio, ip, activo, api_key, cipher, fecha_alta, fecha_expira
    FROM zv_api_key( p_bukrs = @is_api-bukrs, p_servicio = @is_api-servicio )
    WHERE bukrs EQ @is_api-bukrs AND
          servicio EQ @is_api-servicio
*    fecha_expira LE
    INTO TABLE @DATA(lt_api).

    READ TABLE lt_api INTO DATA(ls_api) INDEX 1.



    CHECK sy-subrc EQ 0.

    es_api_sec = VALUE #(
        bukrs = is_api-bukrs
        descripcion = ls_api-descripcion
        key = ls_api-api_key
        cipher = ls_api-cipher
        fecha = ls_api-fecha
        hora = ls_api-hora
        fecha_exp = ls_api-fecha_expira ).

    CHECK is_api-key EQ es_api_sec-key.

    rv_return = abap_true.

  ENDMETHOD.

ENDCLASS.
