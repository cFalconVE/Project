*&---------------------------------------------------------------------*
*& Report  zcl_encrypt_api_key
*&---------------------------------------------------------------------*
*  FECHA DE CREACION: 24.08.2026
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : Class
*  ORDEN          : DR3K981742
*  Solicitud      : REQ-1354
*&---------------------------------------------------------------------*
*   Descripción
*   Generar y guardar API Key encriptada de Servicios API REST
*
*&---------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
* Fecha       Caso    User    Orden       Descripción
*
*
*&---------------------------------------------------------------------*

CLASS zcl_encrypt_api_key DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

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

*      BEGIN OF ty_decry,
*        bukrs TYPE bukrs,
*        key   TYPE xstring,
*      END OF ty_decry,

      BEGIN OF ty_valid_secure,
        bukrs    TYPE bukrs,
        servicio TYPE zservicio,
        key      TYPE xstring,
        host     TYPE zdominios,
        ip       TYPE zhost_ip,
      END OF ty_valid_secure.

    DATA:
      ms_api       TYPE ty_api READ-ONLY,
      mv_encripted TYPE xstring READ-ONLY.

*    DATA lo_apikey TYPE new lcl_encryt_key(  ).

    CLASS-DATA:
      mt_zap_hostk TYPE SORTED TABLE OF zap_host_apik
                    WITH UNIQUE KEY uuid bukrs servicio,

      mt_zap_hostp TYPE SORTED TABLE OF zap_host_apip
                     WITH UNIQUE KEY uuid_k uuid_p.

    METHODS:
      init
        IMPORTING
          !is_api          TYPE ty_api
        EXPORTING
*          ev_api_key       TYPE sysuuid_x16
          ev_api_key       TYPE xstring
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      check_access
        IMPORTING
          !is_check        TYPE ty_valid_secure
*          EXPORTING
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      valid_api_key
        IMPORTING
          !is_check        TYPE ty_valid_secure
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      "!
      "! @parameter iv_pass_key |
      "! @parameter rv_encripted |
      "! @raising cx_sec_sxml_encrypt_error |
      encrypt
        IMPORTING
          !iv_pass_key        TYPE string
        RETURNING
          VALUE(rv_encripted) TYPE xstring
        RAISING
          cx_sec_sxml_encrypt_error,

      "!
      "! @parameter iv_pass_key |
      "! @parameter rv_encripted |
      "! @raising cx_sec_sxml_encrypt_error |
      decrypt
        IMPORTING
          !iv_pass_key        TYPE string
          !iv_encrypted       TYPE xstring
          !iv_algorithm       TYPE string OPTIONAL
        EXPORTING
          !ev_return          TYPE abap_bool
        RETURNING
          VALUE(rv_decripted) TYPE string
        RAISING
          cx_sec_sxml_encrypt_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
    CONSTANTS mv_server TYPE string VALUE 'INNOVO'.

    DATA: mv_encrypted TYPE xstring.

    METHODS:
      valid_pass_key
        IMPORTING
          iv_pass_key     TYPE string
        RETURNING
          VALUE(rv_valid) TYPE abap_bool,

      get_dom
        IMPORTING
          iv_tplst    TYPE tplst
          iv_servicio TYPE zservicio.

ENDCLASS.

CLASS zcl_encrypt_api_key IMPLEMENTATION.

  METHOD init.
    ms_api = VALUE #(
          fecha = is_api-fecha
          hora = is_api-hora
          bukrs = is_api-bukrs
          servicio = is_api-servicio
          descrip = is_api-descrip
          host = is_api-host
          ip = is_api-ip
          fecha_exp = is_api-fecha_exp ).

*    ms_api-ifecha = is_api-fecha.

    DATA(lo_apikey) = NEW lcl_encryt_key( ).

    lo_apikey->create_api_key(
      EXPORTING
        is_api     = ms_api
      IMPORTING
        ev_api_key = ev_api_key
      RECEIVING
        rv_return  = rv_return ).

  ENDMETHOD.

  METHOD decrypt.

    IF iv_algorithm IS INITIAL.
      DATA(lv_algorithm) = cl_sec_sxml_writer=>co_aes256_algorithm.
    ELSE.
      lv_algorithm = iv_algorithm.
    ENDIF.

    " Convert string to xstring
    DATA lv_key TYPE xstring.

    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text   = iv_pass_key "'MySecret'
      IMPORTING
        buffer = lv_key.

    TRY.
        cl_sec_sxml_writer=>decrypt(
          EXPORTING
            ciphertext = iv_encrypted
            key        = lv_key "iv_pass_key   CONV #( lv_key )
            algorithm  = lv_algorithm
          IMPORTING
            plaintext  = DATA(lv_decrypted) ).

*        rv_decripted = cl_abap_conv_in_ce=>create( )->convert( lv_decrypted ).
        rv_decripted = cl_abap_codepage=>convert_from(
                   source                        = lv_decrypted
*                   codepage                      = codepage
*                   endian                        = endian
*                   replacement                   = replacement
*                   ignore_cerr                   = ignore_cerr
               ).
*                 CATCH cx_parameter_invalid_range.  "
*                 CATCH cx_sy_codepage_converter_init.  "
*                 CATCH cx_sy_conversion_codepage.  "
*                 CATCH cx_parameter_invalid_type.  "
*        conv_in_ce=>create( )->convert( lv_decrypted ).
*        convert_to( iv_string )
      CATCH cx_sec_sxml_encrypt_error.
        RAISE EXCEPTION TYPE cx_sec_sxml_encrypt_error.
    ENDTRY.

    DATA(lv_valid) = valid_pass_key( rv_decripted ).

    IF valid_pass_key( rv_decripted ) EQ abap_false.
      RETURN.
    ENDIF.

    CHECK lv_valid EQ abap_true.

    ev_return = abap_true.

  ENDMETHOD.

  METHOD encrypt.

    TRY.
        cl_sec_sxml_writer=>encrypt(
          EXPORTING
            plaintext  = mv_encrypted
            key        = CONV #( iv_pass_key )
            algorithm  = cl_sec_sxml_writer=>co_aes256_algorithm
          IMPORTING
            ciphertext = rv_encripted ).
      CATCH cx_sec_sxml_encrypt_error.
        RAISE EXCEPTION TYPE cx_sec_sxml_encrypt_error.
    ENDTRY.

    mv_encripted = rv_encripted.

    cl_demo_output=>display( rv_encripted ).

  ENDMETHOD.


  METHOD get_dom.

*    SELECT *
*      FROM zap_dominios_val
*      INTO TABLE @mt_zap_dom
*     WHERE bukrs EQ @iv_tplst AND
*           servicio EQ @iv_servicio.

  ENDMETHOD.

  METHOD valid_pass_key.
    CONSTANTS lc_fecha TYPE d VALUE '00010101'.
*Soc  Fecha
*1200 739762
    TYPES:
      BEGIN OF ty_pass_key,
        tplst    TYPE tplst,
        servicio TYPE zservicio,
        fecha    TYPE d,
      END OF ty_pass_key,

      BEGIN OF ty_split,
        tplst    TYPE tplst,
        fecha    TYPE string,
        servicio TYPE zservicio,
      END OF ty_split.

    DATA:
      lv_tplst     TYPE tplst,
      lv_fecha_key TYPE i,
      lv_fecha_dec TYPE d.

    DATA:
      st_dom      TYPE zap_dominios_val,
      st_pass_key TYPE ty_pass_key,
      st_split    TYPE ty_split.

    SPLIT iv_pass_key+1 AT ' '
        INTO st_split-tplst
             st_split-fecha
             st_split-servicio.

*    lv_tplst = iv_pass_key+1(4).
*    lv_fecha_key = iv_pass_key+5.

*    st_pass_key-tplst = iv_pass_key+1(4).
*    st_pass_key-fecha = lc_fecha + lv_fecha_key.
    lv_fecha_key = st_split-fecha.

    st_pass_key = VALUE #( tplst = st_split-tplst
                           fecha = lc_fecha + st_split-fecha
                           servicio = st_split-servicio ).

    DATA(lv_fec_decryted) = lc_fecha + lv_fecha_key.
*    lv_fecha_dec = lc_fecha + lv_fecha_key.

    CHECK sy-datum EQ lv_fec_decryted.

    CHECK sy-datum EQ st_pass_key-fecha.

    WRITE / 'Fecha correcta'.

    SELECT SINGLE butxt
      INTO @DATA(lv_butxt)
      FROM t001 WHERE bukrs = @st_pass_key-tplst.

    CHECK sy-subrc EQ 0.

*    IF NOT line_exists( mt_zap_dom[ bukrs = st_pass_key-tplst
*                                    servicio = st_pass_key-servicio ] ).
*      SELECT bukrs, matnr, maktx, matkl, meinh, werks, lgort
*       FROM zv_dot_mat_per
*      WHERE bukrs EQ @me->mv_bukrs
*      APPENDING TABLE @lt_mat_per.
*    ENDIF.

    rv_valid = abap_true.

  ENDMETHOD.

  METHOD check_access.
    DATA(lo_apikey) = NEW lcl_encryt_key( ).

*    lo_apikey->check_api_key( is_check = is_check ).

    rv_return = lo_apikey->check_api_key( is_check = is_check ).

  ENDMETHOD.

  METHOD valid_api_key.

  ENDMETHOD.

ENDCLASS.
