CLASS zcl_sd_innovo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_conductor,
        nacionalidad TYPE z_nacionalidad,
        cedula       TYPE zciconductor,
        email        TYPE zcorreo,
        exp_licencia TYPE dats,
        exp_salud    TYPE dats,
        nombre       TYPE zconductor,
        apellido     TYPE zconductor,
        rif          TYPE stcd1,
        telefono     TYPE telf1,
        transporte   TYPE zname1,
        activo       TYPE zsd_status_activo,
      END OF ty_conductor,

      tt_conductor TYPE STANDARD TABLE OF ty_conductor
       WITH NON-UNIQUE KEY cedula,

      BEGIN OF ty_ambiente,
        sysid   TYPE sy-sysid,
        url     TYPE zurl,
        api_key TYPE string,
      END OF ty_ambiente,

      BEGIN OF ty_response_item,
        code   TYPE string,
        title  TYPE string,
        detail TYPE string,
      END OF ty_response_item,

      tt_response_list TYPE STANDARD TABLE OF ty_response_item WITH EMPTY KEY.

    DATA:
      mv_json    TYPE string READ-ONLY,
      mv_tplst   TYPE tplst,
      mv_tknum   TYPE tknum READ-ONLY,
      mv_transp  TYPE abap_bool READ-ONLY,
      mv_drivers TYPE abap_bool READ-ONLY,
      mv_display TYPE abap_bool READ-ONLY,
      mv_type    TYPE c1 READ-ONLY,
*      ms_amb     TYPE ty_ambiente READ-ONLY
      ms_amb     TYPE zsd_st_serv_url READ-ONLY.

    METHODS:
      constructor
        IMPORTING
          iv_tplst   TYPE tplst OPTIONAL
          iv_tknum   TYPE tknum
          iv_json    TYPE string
          is_amb     TYPE zsd_st_serv_url
          iv_type    TYPE c1 OPTIONAL
          iv_mostrar TYPE abap_bool OPTIONAL,

      init
        IMPORTING
          iv_list_transp  TYPE abap_bool OPTIONAL
          iv_list_drivers TYPE abap_bool
          iv_type         TYPE c1,

      send_despacho
*        IMPORTING
*          is_amb           TYPE ty_ambiente
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      exit_despacho
        IMPORTING
          is_romana        TYPE zsd_tb_romanak
        CHANGING
          et_resp_list     TYPE tt_response_list
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      send_driver
        IMPORTING
          is_driver        TYPE  zsd_tb_drivers
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      save_stat_exit
        RETURNING VALUE(rv_return) TYPE abap_bool,

      upd_carriers
        IMPORTING
          iv_rif           TYPE lifnr OPTIONAL
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      status_stage
        IMPORTING
          is_stage         TYPE zsd_st_stage
        CHANGING
          et_resp_list     TYPE tt_response_list
        RETURNING
          VALUE(rv_return) TYPE abap_bool.

  PROTECTED SECTION.

  PRIVATE SECTION.
    METHODS:
      post_list_transp
        IMPORTING
          iv_rif TYPE lifnr OPTIONAL,

      post_list_drivers,

      load_url
        RETURNING VALUE(rv_return) TYPE zsd_st_serv_url.

ENDCLASS.

CLASS zcl_sd_innovo IMPLEMENTATION.

  METHOD constructor.
    mv_json = iv_json.
    mv_tknum = iv_tknum.
    mv_display = iv_mostrar.
    mv_type = iv_type.

    IF iv_tplst IS NOT INITIAL.
      mv_tplst = iv_tplst.
    ENDIF.

    IF is_amb IS INITIAL.
      ms_amb = load_url( ).
    ELSE.
      ms_amb = is_amb.
    ENDIF.

  ENDMETHOD.

  METHOD init.
    mv_transp = iv_list_transp.
    mv_drivers = iv_list_drivers.

    IF mv_transp EQ abap_true.
      post_list_transp( ).
    ENDIF.

    IF mv_drivers EQ abap_true.
      post_list_drivers( ).
    ENDIF.

  ENDMETHOD.

  METHOD post_list_transp.
    DATA(lo_serv) = NEW lcl_servicios( is_amb = ms_amb ).

    IF lo_serv->post_carriers( iv_rif ) EQ abap_false.
      MESSAGE 'No se pudo enviar el transporte' TYPE 'E'.
    ENDIF.

  ENDMETHOD.

  METHOD post_list_drivers.
    DATA(lo_serv) = NEW lcl_servicios( is_amb = ms_amb ).

    IF lo_serv->post_drivers( ) EQ abap_false.
      MESSAGE 'No se pudo enviar la lista de conductores' TYPE 'E'.
    ENDIF.

  ENDMETHOD.

  METHOD send_despacho.
    DATA(lo_serv) = NEW lcl_servicios( is_amb = ms_amb ).

    rv_return = lo_serv->send_despacho(
                    iv_tknum  = mv_tknum
                    iv_json   = mv_json  ).
  ENDMETHOD.

  METHOD exit_despacho.
    DATA(lo_serv) = NEW lcl_servicios( is_amb = ms_amb ).

    rv_return = lo_serv->exit_despacho(
      EXPORTING
*        iv_tkum      = mv_tknum
        is_transp = is_romana
      CHANGING
        et_resp_list = et_resp_list ).
  ENDMETHOD.

  METHOD send_driver.
    DATA(lo_innovo) = NEW lcl_servicios(
        is_amb = ms_amb ).

    rv_return = lo_innovo->send_driver( is_driver = is_driver ).

  ENDMETHOD.

  METHOD load_url.
    DATA ls_amb TYPE zsd_st_serv_url. " ty_ambiente.

    DATA(lo_serv_url) = NEW zcl_sd_serv_digital( ).

    ls_amb = VALUE #( sysid = sy-sysid
                      bukrs = mv_tplst
                      servicio = 'INNOVO' ).

    lo_serv_url->init( is_service = ls_amb ).

    lo_serv_url->get_services(
      CHANGING
        es_service = ls_amb ).

*    CASE sy-sysid.
*      WHEN 'DR3' OR 'QR3'.
*        lv_amb = VALUE #(
*          sysid = sy-sysid
*          url = |https://qacorimon.innovologistic.innovosite.com/api/v1/integrations|
*          api_key = |l8UIhsE9OJWFpmgFSHzbTsFTBsexPLFpSwYJAdSv| ).
*      WHEN 'PR3'.
*        lv_amb = VALUE #(
*          sysid = sy-sysid
*          url = |https://corimon.innovologistic.innovosite.com/api/v1/integrations|
*          api_key = |DDNrJm698bE3nmNuNY2qPcFumqGjWGVPQuN06tJJ| ).
*    ENDCASE.

    rv_return = ls_amb.

  ENDMETHOD.

  METHOD save_stat_exit.

    SELECT SINGLE tknum, fecha_salida, hora_salida
      INTO @DATA(ls_romak)
      FROM zsd_tb_romanak
      WHERE tplst EQ @mv_tplst AND
            tknum EQ @mv_tknum.

    CHECK sy-subrc EQ 0.

    UPDATE vttk
          SET sttbg = 'X'
              datbg = ls_romak-fecha_salida
              uatbg = ls_romak-hora_salida
        WHERE tknum = ls_romak-tknum.

    CHECK sy-subrc EQ 0.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD upd_carriers.
    DATA(lo_serv) = NEW lcl_servicios( is_amb = ms_amb
                                       iv_type = mv_type ).

    IF lo_serv->post_carriers( iv_rif ) EQ abap_false.
      MESSAGE 'No se pudo enviar el transporte' TYPE 'E'.
    ELSE.
      rv_return = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD status_stage.
    DATA(lo_serv) = NEW lcl_servicios( is_amb = ms_amb ).

*    rv_return = lo_serv->send_despacho(
*                   iv_tknum  = mv_tknum
*                   iv_json   = mv_json  ).

    IF lo_serv->update_stage(
        EXPORTING is_stage     = is_stage
        CHANGING  et_resp_list = et_resp_list ) EQ abap_false.
      MESSAGE 'No se pudo actualizar el transporte' TYPE 'E'.
      RETURN.
    ELSE.
      rv_return = abap_true.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
