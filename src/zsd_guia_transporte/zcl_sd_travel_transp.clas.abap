CLASS zcl_sd_travel_transp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_range,
        sign     TYPE /bcv/fnd_sign_range,
        option   TYPE /bcv/fnd_option,
        low(10)  TYPE c,
        high(10) TYPE c,
      END OF ty_range,

      tt_range TYPE STANDARD TABLE OF ty_range,

      BEGIN OF ty_response_item,
        code   TYPE string,
        title  TYPE string,
        detail TYPE string,
*        fecha  TYPE datum,
*        hora   TYPE sy-uzeit,
      END OF ty_response_item,

      tt_response_list TYPE STANDARD TABLE OF ty_response_item WITH EMPTY KEY,

      BEGIN OF ty_response,
        status       TYPE i,
        reason       TYPE string,
        tdocumento   TYPE ztdocumento,
        nrodocumento TYPE vbeln,
        fecha        TYPE datum,
        hora         TYPE sy-uzeit,
        message      TYPE tt_response_list,
      END OF ty_response,

      tt_response TYPE ty_response,

      BEGIN OF ty_log,
        tplst   TYPE tplst,
        proceso TYPE char3,
        json    TYPE string,
      END OF ty_log,

      tt_json TYPE STANDARD TABLE OF ty_log,

      BEGIN OF ty_ambiente,
        sysid   TYPE sy-sysid,
        url     TYPE zurl,
        api_key TYPE string,
      END OF ty_ambiente.

    DATA:
      lt_resp_list TYPE tt_response_list,
      ls_resp_item TYPE ty_response_item,
      ls_resp      TYPE ty_response,
      lt_tipdoc    TYPE tt_range.

    DATA:
        ms_amb TYPE ty_ambiente READ-ONLY.

    INTERFACES if_http_extension.

    METHODS:
      constructor.

  PROTECTED SECTION.

  PRIVATE SECTION.
    CONSTANTS:
      lc_sistema  TYPE string VALUE 'QR3',
      mc_url      TYPE string VALUE 'https://qa.grupocorimon.com:8443/sap/bc/rest/z_despacho_dig/',
      lc_spras(1) TYPE c VALUE 'S'.

    TYPES:
      BEGIN OF ty_error_item,
        code   TYPE string,
        title  TYPE string,
        detail TYPE string,
      END OF ty_error_item,

      ty_error_list TYPE STANDARD TABLE OF ty_error_item WITH EMPTY KEY,

      BEGIN OF ty_error_response,
        status TYPE i,
        reason TYPE string,
        errors TYPE ty_error_list,
      END OF ty_error_response,

      tt_error_resp TYPE ty_error_response,

      BEGIN OF ty_guia,
        tplst  TYPE tplst,
        tknum  TYPE tknum,
        dig_sl TYPE abap_bool,
      END OF ty_guia,

      tt_guia TYPE ty_guia,

      BEGIN OF ty_json,
        id(3) TYPE c,
        json  TYPE string,
      END OF ty_json,

      BEGIN OF ty_json_i,
        id   TYPE i,
        json TYPE string,
      END OF ty_json_i,

      BEGIN OF ty_desp,
        gc   TYPE string,
        fac  TYPE string,
        oe   TYPE string,
        desp TYPE string,
      END OF ty_desp,

      BEGIN OF ty_recep,
        tdocumento      TYPE ztdocumento,
        nrodocumento    TYPE vbeln,
        fecha_recepcion TYPE string,
      END OF ty_recep,

      BEGIN OF ty_endruta,
        tdocumento   TYPE ztdocumento,
        nrodocumento TYPE tknum,
        fecha_fin    TYPE string,
        hora_fin     TYPE string,
      END OF ty_endruta,

      tt_enddruta TYPE STANDARD TABLE OF ty_endruta,

      BEGIN OF ty_response1,
        id           TYPE i,
        status       TYPE string,
        tdocumento   TYPE ztdocumento,
        nrodocumento TYPE vbeln,
        message      TYPE string,
        fecha        TYPE datum,
        hora         TYPE sy-uzeit,
      END OF ty_response1,

      ty_incidente TYPE STANDARD TABLE OF zsd_st_inc_desp.

    DATA: lt_errors     TYPE ty_error_list,
          ls_error_item TYPE ty_error_item,
          ls_error_resp TYPE ty_error_response.

    DATA: lv_status_code  TYPE i VALUE 400, " Código HTTP
          lv_reason       TYPE string VALUE 'Bad Request',
          lv_json_error   TYPE string,
          lv_json_message TYPE string.

    DATA request TYPE REF TO if_http_request.

    DATA:
      lo_client   TYPE REF TO if_http_client,
      lo_response TYPE REF TO if_http_response,
      lv_response TYPE string,
*      ls_json_sta    TYPE zsd_st_json_status,
*      ls_tb_json_sta TYPE zsd_tb_json_stat,
      lv_code     TYPE string,
      lv_json     TYPE string,
      ls_log      TYPE ty_log.

    DATA lo_json TYPE REF TO /ui2/cl_json.

    METHODS:
      handle_guia_crp
        IMPORTING
          io_server TYPE REF TO if_http_server,

      handle_get
        IMPORTING
                  iv_request  TYPE REF TO if_http_request
                  iv_response TYPE REF TO if_http_response
        EXPORTING es_guia     TYPE ty_guia,

      handle_conductor
        IMPORTING
          io_server TYPE REF TO if_http_server,

      handle_post
        IMPORTING
          io_server TYPE REF TO if_http_server,

      handle_recep_crp
        IMPORTING
          io_server          TYPE REF TO if_http_server
          iv_tplst           TYPE tplst
        RETURNING
          VALUE(rv_response) TYPE string,
*        RAISING
*          cx_root,

      handle_incid_crp
        IMPORTING
          io_server          TYPE REF TO if_http_server
          iv_tplst           TYPE tplst
        RETURNING
          VALUE(rv_response) TYPE string,

      handle_fin_ruta
        IMPORTING
          io_server          TYPE REF TO if_http_server
          iv_tplst           TYPE tplst
        RETURNING
          VALUE(rv_response) TYPE string,

      handle_ini_or
        IMPORTING
          io_server          TYPE REF TO if_http_server
          iv_tplst           TYPE tplst
        RETURNING
          VALUE(rv_response) TYPE string,
*        RAISING
*          cx_root,

      send_json
        IMPORTING
          iv_response TYPE REF TO if_http_response
          iv_data     TYPE string
          iv_code     TYPE i DEFAULT 200
          iv_reason   TYPE string DEFAULT 'OK',

      send_error
        IMPORTING
          io_server  TYPE REF TO if_http_server
          iv_code    TYPE i
          iv_message TYPE string,

      save_recep
        IMPORTING
          iv_tplst         TYPE tplst
          is_recep         TYPE ty_recep
        EXPORTING
          ev_code          TYPE i
          ev_reason        TYPE string
          ev_message       TYPE string
        CHANGING
          et_resp_list     TYPE tt_response_list
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      save_incid
        IMPORTING
          iv_tplst         TYPE tplst
          it_incid         TYPE ty_incidente "zsd_st_inc_desp
        EXPORTING
          ev_code          TYPE i
          ev_reason        TYPE string
          ev_message       TYPE string
          es_incid         TYPE zsd_st_inc_desp
          es_response      TYPE ty_response
        CHANGING
          et_resp_list     TYPE tt_response_list
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      commit_work,

      roolback_work.

ENDCLASS.

CLASS zcl_sd_travel_transp IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    DATA:
      lv_path_info      TYPE string,
      lv_request_method TYPE string,
      lv_env(1)         TYPE c,
      lv_socied         TYPE bukrs,
      lv_client         TYPE kunnr.

    TYPES:
      tt_json   TYPE STANDARD TABLE OF ty_json,
      tt_json_i TYPE STANDARD TABLE OF ty_json_i,

      BEGIN OF ty_desp,
        gc   TYPE string,
        fac  TYPE string,
        oe   TYPE string,
        desp TYPE string,
      END OF ty_desp.

    DATA:
      ls_guia   TYPE ty_guia,
      mv_json   TYPE string,
      gs_desp   TYPE ty_desp,
      gt_json   TYPE tt_json,
      gt_json_i TYPE tt_json_i.

    DATA:
      lt_errors     TYPE ty_error_list,
      ls_error_item TYPE ty_error_item,
      ls_error_resp TYPE ty_error_response.

    DATA:
*          lv_method   TYPE string,
*      lo_request  TYPE REF TO if_http_request,
*      lo_response TYPE REF TO if_http_response,
      lt_json     TYPE string.

    DATA:
      it_inputparams TYPE tihttpnvp,
      ls_inputparams TYPE LINE OF tihttpnvp.

    FIELD-SYMBOLS <fs_param> TYPE LINE OF tihttpnvp.

    CLEAR lt_errors.

    lt_tipdoc = VALUE #(
          ( option = 'EQ' sign = 'I' low = 'FAC' )
          ( option = 'EQ' sign = 'I' low = 'OE' )
          ( option = 'EQ' sign = 'I' low = 'OR' ) ).

*esquema de seguridad alterno (i)
    DATA: lt_header_fields TYPE tihttpnvp,
          response         TYPE REF TO if_http_response.
*          ls_header_field  TYPE LINE OF tihttpnvp,
*          lv_text          TYPE string

**    " Obtener objetos request y response
*    lo_request  = server->request.
*    lo_response = server->response.
*    BREAK-POINT.
    TRY.
        DATA(lv_method) = server->request->get_header_field( '~request_method' ).
        DATA(lv_path) = server->request->get_header_field( '~path_info' ).

        TRANSLATE lv_method TO UPPER CASE.

        CASE lv_method.
          WHEN 'GET'.
            CASE lv_path.
              WHEN '/get_guia_crp'.
                handle_guia_crp( server ).
              WHEN '/get_conductor'.
                handle_conductor( server ).
            ENDCASE.
*            handle_get(
*                EXPORTING
*                    iv_request = lo_request
*                    iv_response = lo_response
*                IMPORTING
*                    es_guia  = ls_guia ).
          WHEN 'POST'.
*            CASE lv_path.
*              WHEN '/recep_crp'.
*                handle_post_crp( server ).
*            ENDCASE.
            handle_post( server ).

*            handle_post( iv_request = request iv_response = response ).
          WHEN OTHERS.
            send_json( iv_response = server->response
                       iv_data     = '{"error":"Método no soportado"}'
                       iv_code     = 405 ).
        ENDCASE.

      CATCH cx_root INTO DATA(lx_err).
        lv_status_code = 500.
        lv_reason = |Error Interno del servidor|.

        ls_error_item = VALUE #(
           code = 'E0001'
           title = 'Error Interno del servidor'
           detail = |No se pudo enviar el documento { ls_guia-tknum } error: { lx_err->get_text( ) }| ).

        APPEND ls_error_item TO lt_errors.

        ls_error_resp = VALUE #(
            status = lv_status_code
            reason = lv_reason
            errors = lt_errors ).

*        " Armar respuesta
*        ls_error_resp-status = lv_status_code.
*        ls_error_resp-reason = lv_reason.
*        ls_error_resp-errors = lt_errors.

*        ls_error_item-code   = 'E001'.
*        ls_error_item-title  = 'Campo obligatorio faltante'.
*        ls_error_item-detail = 'El campo "usuario" es requerido y no fue enviado.'.

        lv_json_error = /ui2/cl_json=>serialize(
                           data        = ls_error_resp
                           pretty_name = /ui2/cl_json=>pretty_mode-low_case
                           compress    = abap_false ).

        send_json( iv_response = server->response
                   iv_data     = lv_json_error
                   iv_code     = 500 ).

*        send_json( iv_response = lo_response
*                   iv_data     = |error: { lx_err->get_text( ) }|
*                   iv_code     = 500 ).
    ENDTRY.

    server->request->get_header_fields( CHANGING fields = lt_header_fields[] ).
*    server->request->get_header_fields( CHANGING fields = lt_header_fields[] ).

    DATA(lo_check) = NEW lcl_seguridad_web( iv_header = lt_header_fields[] ).

    TRY.
        lo_check->check_web(
            RECEIVING
                rv_return          = DATA(lv_receiber)
            EXCEPTIONS
                error_unauthorized = 1
                OTHERS             = 2 ).

        IF sy-subrc <> 0.
          RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
        ENDIF.

      CATCH cx_sy_itab_line_not_found.
        ls_error_item = VALUE #(
             code = 'E0002'
             title = 'No autorizado'
             detail = |No tiene autorización| ).

        APPEND ls_error_item TO lt_errors.
        " Armar respuesta
        ls_error_resp = VALUE #(
            status = lv_status_code
            reason = lv_reason
            errors = lt_errors ).

        lv_json_error = /ui2/cl_json=>serialize(
                           data        = ls_error_resp
                           pretty_name = /ui2/cl_json=>pretty_mode-low_case
                           compress    = abap_false
                        ).
        send_json( iv_response = server->response
                   iv_data     = lv_json_error
                   iv_code     = 500 ).

*        CALL METHOD lo_response->set_status( code = '500' reason = 'No hay datos' ).
        RETURN.
    ENDTRY.

*    "Get request info
*    lv_path_info = server->request->get_header_field( name = '~path_info' ).
    lv_request_method = server->request->get_header_field( name = '~request_method' ).
*
*    "Get GET parameters
*
**    CALL METHOD server->request->get_form_fields
*    CALL METHOD lo_request->get_form_fields
*      CHANGING
*        fields = it_inputparams.
*
*    UNASSIGN <fs_param>.
*
*    LOOP AT it_inputparams ASSIGNING <fs_param>.
*      TRANSLATE <fs_param>-name TO UPPER CASE.
*    ENDLOOP.
*
*    CLEAR ls_inputparams.
*
**    IF ls_guia IS INITIAL.
**
**      ls_error_item = VALUE #(
**               code = 'E0003'
**               title = 'Parametros vacíos'
**               detail = |El transporte { ls_guia-tplst } ó la Guía { ls_guia-tknum }| ).
**
**      APPEND ls_error_item TO lt_errors.
**      " Armar respuesta
**      ls_error_resp = VALUE #(
**          status = lv_status_code
**          reason = lv_reason
**          errors = lt_errors ).
**
**      lv_json_error = /ui2/cl_json=>serialize(
**                         data        = ls_error_resp
**                         pretty_name = /ui2/cl_json=>pretty_mode-low_case
**                         compress    = abap_false
**                      ).
**      send_json( iv_response = lo_response
**                 iv_data     = lv_json_error
**                 iv_code     = 422 ).
**
***      lo_response->set_status( code = '500' reason = 'Parametros vacíos' ).
**      RETURN.
**    ENDIF.

**    IF lv_request_method EQ 'GET'.
**      DATA(lo_trans) = NEW zcl_sd_doc_fd( ).
**
**      TRY.
**          lo_trans->init(
**        EXPORTING
**          is_guia               = ls_guia
**        IMPORTING
**          ev_json_gc            = gs_desp-gc
**          ev_json_oe            = gs_desp-oe
**          ev_json_fa            = gs_desp-fac
**          ev_json_desp          = gs_desp-desp
**          et_json               = gt_json_i ).
**        CATCH cx_abap_invalid_value.    "
***      CATCH cx_ INTO cx.
**          CALL METHOD server->response->set_status( code = '500' reason = 'Error interno' ).
**          RETURN.
**      ENDTRY.
**
**      IF gs_desp-desp IS INITIAL.
**        ls_error_item = VALUE #(
**            code = 'E0002'
**            title = 'No hay datos'
**            detail = |No existe la Guía de carga: { ls_guia-tknum }| ).
**
**        APPEND ls_error_item TO lt_errors.
**        " Armar respuesta
**        ls_error_resp = VALUE #(
**            status = lv_status_code
**            reason = lv_reason
**            errors = lt_errors ).
**
**        lv_json_error = /ui2/cl_json=>serialize(
**                           data        = ls_error_resp
**                           pretty_name = /ui2/cl_json=>pretty_mode-low_case
**                           compress    = abap_false
**                        ).
**        send_json( iv_response = lo_response
**                   iv_data     = lv_json_error
**                   iv_code     = 422 ).
***        CALL METHOD lo_response->set_status( code = '422' reason = 'No existe la Guía de carga' ).
***        CALL METHOD lo_response->set_cdata( 'No existe la Guía de carga' ).
**        RETURN.
**      ENDIF.

*factura 0097028595

**      send_json( iv_response = lo_response
**                 iv_data     = gs_desp-desp ).

*      gt_json = VALUE #(
*        ( id = 'GC' json = gs_desp-gc )
*        ( id = 'FAC' json = gs_desp-fac )
*        ( id = 'OE' json = gs_desp-oe ) ).

*    ENDIF.

    " Configurar cabeceras HTTP
*    lo_response->set_header_field( name  = 'Content-Type'
*                                   value = 'application/json; charset=utf-8' ).

*    CALL METHOD server->response->set_status( code = 200 reason = 'FIN' ).

    " Enviar el JSON
*    lo_response->set_cdata( lv_json_ser ).

  ENDMETHOD.

  METHOD send_json.
    iv_response->set_content_type( 'application/json' ).
    iv_response->set_header_field( name = 'Content-Type'
                                   value = 'application/json; charset=UTF-8' ).
    iv_response->set_status( code = iv_code reason = lv_reason ).
    iv_response->set_cdata( iv_data ).
  ENDMETHOD.

  METHOD handle_get.
    " Ejemplo: obtener parámetros de la URL
*    es_guia-tplst = iv_request->get_form_field( 'soc' ).
    es_guia-tplst = 1200.
    DATA(lv_tknum) = iv_request->get_form_field( 'guia' ).

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_tknum
      IMPORTING
        output = es_guia-tknum.

*    DATA(json) = |method:GET, param1:{ param1 }, param2:{ param2 }|.

*    send_json( iv_response = iv_response iv_data = json ).
  ENDMETHOD.

  METHOD handle_guia_crp.
*    DATA(lv_path) = io_server->request->get_header_field( '~path_info' ).

    DATA: ls_guia   TYPE ty_guia,
          ls_desp   TYPE ty_desp,
          ls_dat_gc TYPE zsd_st_datos_gc.

*    CASE lv_path.
*      WHEN '/get_guia_crp'.

    ls_guia-tplst = 1200.
    DATA(lv_tknum) =  io_server->request->get_form_field( 'guia' ).

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = lv_tknum
      IMPORTING
        output = ls_guia-tknum.

    IF ls_guia-tknum IS INITIAL.

      ls_error_item = VALUE #(
               code = 'E0003'
               title = 'Parametros vacíos'
               detail = |la Guía de transporte está vacía| ).

      APPEND ls_error_item TO lt_errors.
      " Armar respuesta
      ls_error_resp = VALUE #(
          status = lv_status_code
          reason = lv_reason
          errors = lt_errors ).

      lv_json_error = /ui2/cl_json=>serialize(
                         data        = ls_error_resp
                         pretty_name = /ui2/cl_json=>pretty_mode-low_case
                         compress    = abap_false ).

      send_json( iv_response = io_server->response
                 iv_data     = lv_json_error
                 iv_code     = 422 ).

*      lo_response->set_status( code = '500' reason = 'Parametros vacíos' ).
      RETURN.
    ENDIF.

    DATA(lo_trans) = NEW zcl_sd_doc_fd( ).

    TRY.

*     lo_trans->init(
*       EXPORTING
*         is_guia               = is_guia
*         iv_mostrar            = iv_mostrar
**       IMPORTING
**         ev_json_gc            = ev_json_gc
**         ev_json_oe            = ev_json_oe
**         ev_json_fa            = ev_json_fa
**         ev_json_desp          = ev_json_desp
**         et_json               = et_json
*     ).
*       CATCH cx_abap_invalid_value.    " .
        lo_trans->init(
      EXPORTING
        is_guia               = ls_guia
*        is_dat_gc             = ls_dat_gc
      IMPORTING
        ev_json_gc            = ls_desp-gc
        ev_json_oe            = ls_desp-oe
        ev_json_fa            = ls_desp-fac
        ev_json_desp          = ls_desp-desp ).
*            et_json               = gt_json_i
      CATCH cx_abap_invalid_value.    "
*      CATCH cx_ INTO cx.
        CALL METHOD io_server->response->set_status( code = '500' reason = 'Error interno' ).
        RETURN.
    ENDTRY.

    IF ls_desp-desp IS INITIAL.
      ls_error_item = VALUE #(
          code = 'E0002'
          title = 'No hay datos'
          detail = |Verifique la Guía de transporte: { ls_guia-tknum }| ).

      APPEND ls_error_item TO lt_errors.
      " Armar respuesta
      ls_error_resp = VALUE #(
          status = lv_status_code
          reason = lv_reason
          errors = lt_errors ).

      lv_json_error = /ui2/cl_json=>serialize(
                         data        = ls_error_resp
                         pretty_name = /ui2/cl_json=>pretty_mode-low_case
                         compress    = abap_false
                      ).
      send_json( iv_response = io_server->response
                 iv_data     = lv_json_error
                 iv_code     = 422 ).
      RETURN.
    ENDIF.

    send_json( iv_response = io_server->response
               iv_data     = ls_desp-desp ).
*                   iv_code     = 200 ).
*  WHEN '/get_conductor'.

*  WHEN OTHERS.
*    ls_error_item = VALUE #(
*                    code = 'E0003'
*                    title = 'Método GET'
*                    detail = |El método { lv_path } no soportado| ).
*
*    APPEND ls_error_item TO lt_errors.
*    " Armar respuesta
*    ls_error_resp = VALUE #(
*        status = lv_status_code
*        reason = lv_reason
*        errors = lt_errors ).
*
*    lv_json_error = /ui2/cl_json=>serialize(
*                       data        = ls_error_resp
*                       pretty_name = /ui2/cl_json=>pretty_mode-low_case
*                       compress    = abap_false
*                    ).
*    send_json( iv_response = io_server->response
*               iv_data     = lv_json_error
*               iv_code     = 422 ).
*ENDCASE.

  ENDMETHOD.

  METHOD handle_post.
    DATA(lv_path) = io_server->request->get_header_field( '~path_info' ).

    DATA: ls_guia TYPE ty_guia,
          ls_desp TYPE ty_desp.

    CASE lv_path.
      WHEN '/post_guia_crp'.
        ls_error_item = VALUE #(
                code = 'E0002'
                title = 'POST GUIA'
                detail = |POST: { lv_path }| ).

        APPEND ls_error_item TO lt_errors.
        " Armar respuesta
        ls_error_resp = VALUE #(
            status = lv_status_code
            reason = lv_reason
            errors = lt_errors ).

        lv_json_error = /ui2/cl_json=>serialize(
                           data        = ls_error_resp
                           pretty_name = /ui2/cl_json=>pretty_mode-low_case
                           compress    = abap_false
                        ).
        send_json( iv_response = io_server->response
                   iv_data     = lv_json_error
                   iv_code     = 200 ).
      WHEN '/recep_crp'.
        handle_recep_crp(
          EXPORTING
            io_server   = io_server
            iv_tplst    = '1200' ).
      WHEN '/incid_crp'.
        handle_incid_crp(
          EXPORTING
            io_server   = io_server
            iv_tplst    = '1200' ).
      WHEN '/end_desp_crp'.
        handle_fin_ruta(
          EXPORTING
            io_server = io_server
            iv_tplst  = '1200' ).
      WHEN '/ini_ret_crp'.
        handle_ini_or(
          EXPORTING
            io_server = io_server
            iv_tplst  = '1200' ).
      WHEN OTHERS.
        ls_error_item = VALUE #(
                code = 'E0003'
                title = 'Método POST'
                detail = |El método { lv_path } no soportado| ).

        APPEND ls_error_item TO lt_errors.

        " Armar respuesta
        ls_error_resp = VALUE #(
            status = lv_status_code
            reason = lv_reason
            errors = lt_errors ).

        lv_json_error = /ui2/cl_json=>serialize(
                           data        = ls_error_resp
                           pretty_name = /ui2/cl_json=>pretty_mode-low_case
                           compress    = abap_false ).

        send_json( iv_response = io_server->response
                   iv_data     = lv_json_error
                   iv_code     = 404 ).

*        send_json( iv_response = io_server->response
*                   iv_data     = '{"error": "Método no soportado"}'
*                   iv_code     = 405 ).

    ENDCASE.

  ENDMETHOD.

  METHOD send_error.
    io_server->response->set_header_field( name = 'Content-Type'
                                           value = 'application/json' ).
    io_server->response->set_status( code = iv_code reason = iv_message ).
*    server->response->set_data( |{{"error":"{ message }"}}| ).

  ENDMETHOD.

  METHOD handle_conductor.

  ENDMETHOD.

  METHOD handle_recep_crp.
    DATA:
*      lt_drivers TYPE zsd_tt_transporte,
      ls_response TYPE ty_response1,
      lv_url      TYPE string,
      lv_data     TYPE string,
      ls_recep    TYPE ty_recep.

*  METHOD send_json.
    DATA:
*lo_http_client TYPE REF TO if_http_client,
*          lo_rest_client TYPE REF TO cl_rest_http_client,
*          lo_request     TYPE REF TO if_rest_entity,
          lo_response    TYPE REF TO if_http_response.
*          lv_status      TYPE i.

    lo_response = io_server->response.

    CLEAR ls_response.

    TRY.
        io_server->request->get_cdata( RECEIVING data = lv_json ).

        ls_log = VALUE #(
           tplst   = iv_tplst
           proceso = |REC|
           json    = lv_json ).

        DATA(lo_log) = NEW zcl_sd_desp_log( is_json = ls_log ).

*        "obtener el código de estado y la respuesta
*        io_server->response->get_status(
*          IMPORTING
*            code   = lv_status_code
*            reason = lv_reason ).

        " Deserializar JSON a estructura ABAP
        /ui2/cl_json=>deserialize(
          EXPORTING
            json = lv_json
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING
            data = ls_recep ).

        IF lv_json IS INITIAL OR
           ls_recep IS INITIAL.

*          lo_response->set_content_type( 'application/json' ).
*          lo_response->set_status( code = 400 reason = 'Bad Request' ).
*          lv_status_code = 400.
*          lv_reason = |Bad Request|.

          lv_status_code = 500.
          lv_reason = 'Error interno'.

          ls_resp_item = VALUE #(
                code = |E{ lv_status_code }|
                title = |Error de Lectura del JSON|
                detail = |Recepción: JSON vacío o Error en la estructura del JSON| ).

          APPEND ls_resp_item TO lt_resp_list.

          " Armar respuesta
          ls_resp = VALUE #(
              status = lv_status_code
              reason = lv_reason
              fecha = sy-datum
              hora = sy-uzeit
              message = lt_resp_list ).

          lv_json_message = /ui2/cl_json=>serialize(
                     data        = ls_resp
                     pretty_name = /ui2/cl_json=>pretty_mode-low_case
                     compress    = abap_false ).

*          ls_response = VALUE #( id = 400
*                                 status = 'Error de Lectura del JSON'
*                                 fecha = sy-datum
*                                 hora = sy-uzeit
*                                 message = 'Recepción: JSON vacío o Error en la estructura del JSON' ).
*
*          lo_response->set_cdata( /ui2/cl_json=>serialize( data = ls_response ) ).

          send_json( iv_response = io_server->response
                     iv_code     = lv_status_code
                     iv_reason   = lv_reason
                     iv_data     = lv_json_message ).

          lo_log->save_tracking(
            EXPORTING
                iv_tplst     = iv_tplst
                is_resp_ino  = ls_resp ).

          RETURN.
        ENDIF.

        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING
            input  = ls_recep-nrodocumento
          IMPORTING
            output = ls_recep-nrodocumento.

        save_recep(
          EXPORTING
            iv_tplst   = '1200'
            is_recep   = ls_recep
          IMPORTING
            ev_code      = lv_status_code
            ev_reason    = lv_reason
            ev_message = lv_json_message
          CHANGING
            et_resp_list = lt_resp_list[] ).

*        IF save_recep( iv_tplst = '1200' is_recep = ls_recep ) EQ abap_true.
*          ls_response = VALUE #( id = 200
*                                 status = 'OK'
*                                 tdocumento = ls_recep-tdocumento
*                                 nrodocumento = ls_recep-nrodocumento
*                                 message = 'Registro guardado correcto' ).
*          lo_response->set_status( code = 200 reason = 'OK' ).
*        ELSE.
*          ls_response = VALUE #( id = 500
*                                 status = 'ErrorDB'
*                                 tdocumento = ls_recep-tdocumento
*                                 nrodocumento = ls_recep-nrodocumento
*                                 message = 'No se pudo guardar el registro' ).
*          lo_response->set_status( code = 500 reason = 'Error Interno' ).
*        ENDIF.

      CATCH cx_root INTO DATA(lx_err).
        lo_response->set_content_type( 'application/json' ).
        rv_response = lx_err->get_text( ).
        lo_response->set_status( code = 500 reason = 'Server Error' ).

        ls_response = VALUE #( id = 500
                               status = 'Error Servicio'
                               tdocumento = ls_recep-tdocumento
                               nrodocumento = ls_recep-nrodocumento
                               message = 'Error en la estructura del JSON' ).

*        lo_response->set_cdata( lx_err->get_text( ) ).
    ENDTRY.

*    " Devolver respuesta en JSON
*    lo_response->set_content_type( 'application/json' ).
*    lo_response->set_cdata( /ui2/cl_json=>serialize( data = ls_response ) ).

    " Armar respuesta
    ls_resp = VALUE #(
        status = lv_status_code
        reason = lv_reason
        tdocumento = ls_recep-tdocumento
        nrodocumento = ls_recep-nrodocumento
        fecha = sy-datum
        hora = sy-uzeit
        message = lt_resp_list ).

    lv_json_message = /ui2/cl_json=>serialize(
               data        = ls_resp
               pretty_name = /ui2/cl_json=>pretty_mode-low_case
               compress    = abap_false ).

    send_json( iv_response = io_server->response
               iv_code     = lv_status_code
               iv_reason   = lv_reason
               iv_data     = lv_json_message ).

    lo_log->save_tracking(
       EXPORTING
         iv_tplst     = iv_tplst
         is_resp_ino  = ls_resp ).

  ENDMETHOD.

  METHOD save_recep.
    DATA: ls_rec_desp TYPE zsd_recep_desp,
          lv_date     TYPE sy-datum,
          lv_hours    TYPE sy-uzeit,
          lv_result   TYPE c LENGTH 1.

    lv_status_code = 422.
    lv_reason = 'Datos no procesados'.

    lv_date = |{ is_recep-fecha_recepcion+0(4) }{ is_recep-fecha_recepcion+5(2) }{ is_recep-fecha_recepcion+8(2) }|.
    lv_hours = |{ is_recep-fecha_recepcion+11(2) }{ is_recep-fecha_recepcion+14(2) }{ is_recep-fecha_recepcion+17(2) }|.

    IF is_recep-tdocumento NOT IN lt_tipdoc.
      ls_resp_item = VALUE #(
          code = |E-{ lv_status_code }|
          title = |Tipo de documento no válido|
          detail = |El tipo de documento { is_recep-tdocumento } no es válido| ).

      APPEND ls_resp_item TO et_resp_list.
    ENDIF.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
      EXPORTING
        date                      = lv_date
      EXCEPTIONS
        plausibility_check_failed = 1
        OTHERS                    = 2.

    IF sy-subrc NE 0.
      ls_resp_item = VALUE #(
           code = |E-{ lv_status_code }|
           title = |Formato de la fecha invalido|
           detail = |La fecha { lv_date } es invalida| ).

      APPEND ls_resp_item TO et_resp_list.
    ENDIF.

    CALL FUNCTION 'TIME_CHECK_PLAUSIBILITY'
      EXPORTING
        time         = lv_hours
      EXCEPTIONS
        invalid_time = 1
        OTHERS       = 2.

    IF sy-subrc NE 0.
      ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Formato de la hora invalido|
            detail = |La hora { lv_hours } es invalida| ).

      APPEND ls_resp_item TO et_resp_list.
    ENDIF.

    IF is_recep-nrodocumento IS INITIAL.
      ls_resp_item = VALUE #(
          code = |E-{ lv_status_code }|
          title = |Número de documento está vacío|
          detail = |El número de documento está vacío| ).

      APPEND ls_resp_item TO et_resp_list.
    ELSE.

      DATA(lv_tdoc) = COND  ztdocumento(
        WHEN is_recep-tdocumento EQ 'OR'
            THEN 'LR'
        ELSE is_recep-tdocumento ).

      "Valida que exista el documento
      SELECT SINGLE vbeln
        INTO @DATA(lv_vbeln)
        FROM zsd_tb_json_stat
        WHERE bukrs = @iv_tplst AND
              tdocumento EQ @lv_tdoc AND
              vbeln EQ @is_recep-nrodocumento.

      IF sy-subrc NE 0.
        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Número de documento no existe|
            detail = |El documento { is_recep-tdocumento }-{ is_recep-nrodocumento } no exite| ).

        APPEND ls_resp_item TO et_resp_list.
      ELSE.
        SELECT SINGLE vbeln
          INTO @lv_vbeln
          FROM zsd_recep_desp
          WHERE bukrs = @iv_tplst AND
                tdocumento EQ @is_recep-tdocumento AND
                vbeln EQ @is_recep-nrodocumento.

        IF sy-subrc NE 0.
*          lv_status_code = 201.
*          lv_reason = 'OK'.
*
*          ls_resp_item = VALUE #(
*              code = |{ lv_reason }-{ lv_status_code }|
*              title = |Número de documento ya existe|
*              detail = |El documento { is_recep-tdocumento }-{ is_recep-nrodocumento } ya existe| ).
*
*          lv_reason = 'Documento consultado'.
*
*          APPEND ls_resp_item TO et_resp_list.
*          rv_return = abap_true.
*        ELSE.
          ls_rec_desp = VALUE #( bukrs = iv_tplst
                              tdocumento = is_recep-tdocumento
                              vbeln = is_recep-nrodocumento
                              aenam = sy-uname
                              aedat = lv_date
                              aezet = lv_hours ).

          INSERT zsd_recep_desp FROM ls_rec_desp.

          IF sy-subrc EQ 0.
            commit_work( ).
            lv_status_code = 200.
            lv_reason = |OK|.

            rv_return = abap_true.
          ELSE.
            roolback_work( ).
            lv_status_code = 422.
            lv_reason = 'Bad Request'.

            ls_resp_item = VALUE #(
              code = |{ lv_reason }-{ lv_status_code }|
              title = |No se pudo actualizar la data|
              detail = |El documento: { is_recep-tdocumento }-{ is_recep-nrodocumento } no se guardo| ).

            APPEND ls_resp_item TO et_resp_list.

*            " Armar respuesta
*            ls_resp = VALUE #(
*                status = lv_status_code
*                reason = lv_reason
*                fecha = sy-datum
*                hora = sy-uzeit
*                message = lt_resp_list ).

          ENDIF.
        ELSE.
          lv_status_code = 200.
          lv_reason = |OK|.
          rv_return = abap_true.
        ENDIF.

      ENDIF.
    ENDIF.

    IF rv_return EQ abap_true.
      "Si el documento es FAC actualiza la fecha de recepción de la factura
      IF is_recep-tdocumento EQ 'FAC'.

        SELECT SINGLE procesado
          INTO @DATA(lv_status)
          FROM zsd_recep_desp
          WHERE vbeln EQ @is_recep-nrodocumento.

        IF sy-subrc EQ 0 AND
           lv_status IS INITIAL.

          DATA(lo_fecrec) = NEW zcl_actualiza_fechrecp( ).

          "Actualiza la recepción de la factura
          lo_fecrec->fecharecep(
            EXPORTING
              factura = is_recep-nrodocumento   " Factura
            IMPORTING
                error   = DATA(lv_resp) ).

          ls_resp_item = VALUE #(
            code = lv_resp+0(3)
            title = |Recepcion-{ is_recep-nrodocumento }|
            detail = |Mensaje: { lv_resp }| ).

          APPEND ls_resp_item TO et_resp_list.

          IF lv_resp+0(3) EQ '100' OR
             lv_resp+0(3) EQ '101'.

            lv_status_code = 200.
            lv_reason = |OK|.

            ls_resp_item = VALUE #(
                code = |200|
                title = |Fecha actualizada|
                detail = |El documento: { is_recep-tdocumento }-{ is_recep-nrodocumento } { lv_resp }| ).
          ELSE.
            rv_return = abap_false.
            lv_status_code = 422.
            lv_reason = 'Bad Request'.

            ls_resp_item = VALUE #(
                  code = lv_status_code
                  title = |Documento no fue tratado|
                  detail = |El documento: { is_recep-tdocumento }-{ is_recep-nrodocumento } Código: { lv_resp }| ).
          ENDIF.

          APPEND ls_resp_item TO et_resp_list.

        ENDIF.

      ENDIF.

*      lv_status_code = 200.
*      lv_reason = 'OK'.

      IF rv_return EQ abap_true.
        ls_resp_item = VALUE #(
          code = |200| "|{ lv_reason }-{ lv_status_code }|
          title = |Se guardo el documento|
          detail = |El documento: { is_recep-tdocumento }-{ is_recep-nrodocumento } se guardo con éxito| ).

        APPEND ls_resp_item TO et_resp_list.
      ENDIF.

    ENDIF.

    ev_code = lv_status_code.
    ev_reason = lv_reason.

*    ev_message = lo_json->serialize(
*                      EXPORTING
*                        data        = ls_resp
*                        pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

*    zcl_json_utility=>convert_stuct_to_json(
*        EXPORTING
*            im_s_data = ls_resp
*            im_v_case = zcl_json_utility=>co_ftype_camelcase
*        RECEIVING
*            rt_v_json = ev_message ).
  ENDMETHOD.

  METHOD commit_work.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.

*    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
**      IMPORTING
**        return =     " Return Messages.
  ENDMETHOD.

  METHOD roolback_work.
    CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'
*      IMPORTING
*        return =     " Return Messages
      .
  ENDMETHOD.

  METHOD handle_incid_crp.
    DATA:
      ls_response  TYPE ty_response1,
      lv_data      TYPE string,
      ls_incidente TYPE zsd_st_inc_desp,
      lt_incidente TYPE STANDARD TABLE OF zsd_st_inc_desp,
      lo_json      TYPE REF TO /ui2/cl_json.

*  METHOD send_json.
    DATA lo_response TYPE REF TO if_http_response.

    lo_response = io_server->response.

    CLEAR ls_response.

    TRY.
        io_server->request->get_cdata( RECEIVING data = lv_json ).

        ls_log = VALUE #(
            tplst   = iv_tplst
            proceso = |IIN|  "Innovo Incidencia
            json    = lv_json ).

        DATA(lo_log) = NEW zcl_sd_desp_log( is_json = ls_log ).

*        "obtener el código de estado y la respuesta
*        io_server->response->get_status(
*          IMPORTING
*            code   = lv_status_code
*            reason = lv_reason ).

        " Crear instancia del parser JSON
        lo_json = NEW /ui2/cl_json( ).

        " Deserializar JSON a tabla ABAP
        lo_json->deserialize(
          EXPORTING
            json             = lv_json
*            jsonx            = jsonx
*            pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
*            assoc_arrays     = assoc_arrays
*            assoc_arrays_opt = assoc_arrays_opt
*            name_mappings    = name_mappings
*            conversion_exits = conversion_exits
          CHANGING
            data             = lt_incidente ).

        IF lv_json IS INITIAL OR
           lt_incidente[] IS INITIAL.
          lo_response->set_content_type( 'application/json' ).

          lo_response->set_status( code = 400 reason = 'Empty JSON' ).

          ls_response = VALUE #( id = 400
                                 status = 'JSON vacío'
                                 message = 'La recepción de Factura o Orden de entrega está vacía' ).
*          lo_response->set_status( code = 400 reason = 'Bad Request' ).
          lo_response->set_cdata( /ui2/cl_json=>serialize( data = ls_response ) ).
          RETURN.
        ENDIF.

      CATCH cx_root INTO DATA(lx_err).
        rv_response = lx_err->get_text( ).
        lo_response->set_status( code = 500 reason = 'Server Error' ).
        lo_response->set_cdata( lx_err->get_text( ) ).
    ENDTRY.

    save_incid(
      EXPORTING
        iv_tplst   = iv_tplst
        it_incid   = lt_incidente
      IMPORTING
        ev_code    = lv_status_code
        ev_reason  = lv_reason
        ev_message = lv_json_message
        es_response = ls_resp
        CHANGING
        et_resp_list = lt_resp_list ).

    " Armar respuesta
    ls_resp = VALUE #(
        status = lv_status_code
        reason = lv_reason
        tdocumento = ls_incidente-tipo_documento
        nrodocumento = ls_incidente-numero_documento
        fecha = sy-datum
        hora = sy-uzeit
        message = lt_resp_list ).

    zcl_json_utility=>convert_stuct_to_json(
        EXPORTING
            im_s_data = ls_resp
            im_v_case = zcl_json_utility=>co_ftype_camelcase
        RECEIVING
            rt_v_json = lv_json_message ).

    send_json( iv_response = io_server->response
               iv_code     = lv_status_code
               iv_reason   = lv_reason
               iv_data     = lv_json_message ).

    lo_log->save_tracking(
       EXPORTING
         iv_tplst     = iv_tplst
         is_resp_ino  = ls_resp ).
  ENDMETHOD.

  METHOD save_incid.
    DATA:
      ls_inc_desp TYPE zsd_incid_desp,
      lv_date     TYPE sy-datum,
      lv_hours    TYPE sy-uzeit,
      lv_posnr    TYPE posnr VALUE 10,
      lv_error    TYPE i VALUE IS INITIAL,
      lv_check    TYPE abap_bool,
      lv_unimed   TYPE meins.

    CLEAR:
     lt_resp_list, lv_error.

    lv_check = abap_true.

    CHECK NOT it_incid[] IS INITIAL.

    DATA(lv_cont) = lines( it_incid ).

    READ TABLE it_incid INTO DATA(wa_incid) INDEX 1.

    SELECT COUNT(*)
      FROM zsd_incid_desp
      INTO @DATA(lv_items)
      WHERE vbeln EQ @wa_incid-numero_documento.

    IF sy-subrc EQ 0.
      lv_items = lv_items * 10.
    ELSE.
      lv_items = 0.
    ENDIF.

    lv_posnr = lv_posnr + lv_items.

    LOOP AT it_incid INTO DATA(ls_incid).

      lv_status_code = 422.
      lv_reason = 'Documentos no procesados'.

      lv_date = |{ ls_incid-fecha_emision+6(4) }{ ls_incid-fecha_emision+3(2) }{ ls_incid-fecha_emision+0(2) }|.
      lv_hours = |{ ls_incid-hora_emision+0(2) }{ ls_incid-hora_emision+3(2) }{ ls_incid-hora_emision+6(2) }|.

      IF ls_incid-tipo_documento NOT IN lt_tipdoc.
        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Tipo de documento no válido|
            detail = |El tipo de documento { ls_incid-tipo_documento } no es válido| ).

        APPEND ls_resp_item TO et_resp_list.

        lv_error = lv_error + 1.
        lv_check = abap_false.
      ENDIF.

      CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
        EXPORTING
          date                      = lv_date
        EXCEPTIONS
          plausibility_check_failed = 1
          OTHERS                    = 2.

      IF sy-subrc NE 0.
        ls_resp_item = VALUE #(
             code = |E-{ lv_status_code }|
             title = |Formato de la fecha no valido|
             detail = |La fecha { lv_date } no válida| ).

        APPEND ls_resp_item TO et_resp_list.
        lv_error = lv_error + 1.
        lv_check = abap_false.
      ENDIF.

      CALL FUNCTION 'TIME_CHECK_PLAUSIBILITY'
        EXPORTING
          time         = lv_hours
        EXCEPTIONS
          invalid_time = 1
          OTHERS       = 2.

      IF sy-subrc NE 0.
        ls_resp_item = VALUE #(
              code = |E-{ lv_status_code }|
              title = |Formato de la hora no valido|
              detail = |La hora { lv_hours } no válida| ).

        APPEND ls_resp_item TO et_resp_list.

        lv_error = lv_error + 1.
        lv_check = abap_false.
      ENDIF.

      IF ls_incid-numero_documento IS INITIAL.
        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Número de documento está vacío|
            detail = |El número de documento está vacío| ).

        APPEND ls_resp_item TO et_resp_list.

        lv_error = lv_error + 1.
        lv_check = abap_false.
      ELSE.
        "Validar que exista el documento
        SELECT SINGLE vbeln
          INTO @DATA(lv_vbeln)
          FROM zsd_tb_json_stat
          WHERE bukrs = @iv_tplst AND
                tdocumento EQ @ls_incid-tipo_documento AND
                vbeln EQ @ls_incid-numero_documento.

        IF sy-subrc NE 0.
          ls_resp_item = VALUE #(
              code = |E-{ lv_status_code }|
              title = |Número de documento no existe|
              detail = |El número de documento { ls_incid-tipo_documento }-{ ls_incid-numero_documento } no exite| ).

          APPEND ls_resp_item TO et_resp_list.

          lv_error = lv_error + 1.
          lv_check = abap_false.
        ENDIF.
      ENDIF.

      IF ls_incid-codigo_producto IS INITIAL.
        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Codigo del material está vacío|
            detail = |Para el documento { ls_incid-numero_documento }, el codigo de material está vacío| ).

        APPEND ls_resp_item TO et_resp_list.

        lv_error = lv_error + 1.
        lv_check = abap_false.
      ELSE.
        "Validar que exista el documento
        SELECT SINGLE matnr
          INTO @DATA(lv_matnr)
          FROM mara
          WHERE matnr EQ @ls_incid-codigo_producto .

        IF sy-subrc NE 0.
          ls_resp_item = VALUE #(
              code = |E-{ lv_status_code }|
              title = |Codigo del material no existe|
              detail = |El material { ls_incid-codigo_producto } para el documento { ls_incid-tipo_documento }-{ ls_incid-numero_documento } no exite| ).

          APPEND ls_resp_item TO et_resp_list.

          lv_error = lv_error + 1.
          lv_check = abap_false.
        ENDIF.
      ENDIF.

      IF ls_incid-cantidad IS INITIAL.
        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Cantidad está vacío|
            detail = |La cantidad para el documento { ls_incid-numero_documento }, esta vacio| ).

        APPEND ls_resp_item TO et_resp_list.

        lv_error = lv_error + 1.
        lv_check = abap_false.
      ENDIF.

      IF ls_incid-tipo_excepcion IS INITIAL.
        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Campo está vacío|
            detail = |El tipo de excepción esta vacio| ).

        APPEND ls_resp_item TO et_resp_list.

        lv_error = lv_error + 1.
        lv_check = abap_false.
      ENDIF.

      IF ls_incid-codigo_motivo IS INITIAL.
        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Campo está vacío|
            detail = |El Código del motivo esta vacio| ).

        APPEND ls_resp_item TO et_resp_list.

        lv_error = lv_error + 1.
        lv_check = abap_false.
      ENDIF.

      IF ls_incid-descripcion_motivo IS INITIAL.
        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Campo está vacío|
            detail = |La Descripción del motivo esta vacio| ).

        APPEND ls_resp_item TO et_resp_list.

        lv_error = lv_error + 1.
        lv_check = abap_false.
      ENDIF.

      IF ls_incid-descripcion_motivo IS INITIAL.
        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Campo está vacío|
            detail = |La unidad de medida esta vacio| ).

        APPEND ls_resp_item TO et_resp_list.

        lv_error = lv_error + 1.
        lv_check = abap_false.
      ELSE.
        TRY.
            " Llamada a la función estándar
            CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
              EXPORTING
                input          = ls_incid-unidad
                language       = lc_spras
              IMPORTING
                output         = lv_unimed
              EXCEPTIONS
                unit_not_found = 1
                OTHERS         = 2.

            IF sy-subrc <> 0.
              lv_status_code =  422.
              lv_reason = 'Error Unidad de medida'.

              ls_resp_item = VALUE #(
                  code = |E-{ lv_status_code }|
                  title = |Error Unidad de medida|
                  detail = |La unidad de medida { ls_incid-unidad } del material { ls_incid-codigo_producto } no existe| ).

              APPEND ls_resp_item TO et_resp_list.

              lv_error = lv_error + 1.
              lv_check = abap_false.

            ENDIF.

          CATCH cx_root INTO DATA(lx_err).
*            WRITE: / 'Error:', lx_err->get_text( ).

            lv_status_code = 500.
            lv_reason = |Error Interno del servidor|.

            ls_error_item = VALUE #(
               code = 'E0001'
               title = 'Error Interno del servidor'
               detail = |No se pudo enviar el documento { ls_incid-numero_documento } error: { lx_err->get_text( ) }| ).

            APPEND ls_error_item TO et_resp_list.
            lv_error = lv_error + 1.
            lv_check = abap_false.
        ENDTRY.

        IF sy-subrc NE 0.
          ls_resp_item = VALUE #(
              code = |E-{ lv_status_code }|
              title = |Valor invalido|
              detail = |La unidad de medida { ls_incid-unidad } invalildo| ).

          APPEND ls_resp_item TO et_resp_list.

          lv_error = lv_error + 1.
          lv_check = abap_false.

        ENDIF.
      ENDIF.

      AT NEW numero_documento.
        es_incid = VALUE #( tipo_documento   = ls_incid-tipo_documento
                            numero_documento = ls_incid-numero_documento
                            fecha_emision    = lv_date
                            hora_emision     = lv_hours ).
      ENDAT.

*      iv_date = ls_incid-fecha_emision.

      ls_inc_desp = VALUE #( bukrs          = iv_tplst
                             tdocumento     = ls_incid-tipo_documento
                             vbeln          = ls_incid-numero_documento
                             posnr          = lv_posnr
                             matnr          = ls_incid-codigo_producto
                             charg          = ls_incid-numero_lote
                             zieme          = lv_unimed
                             smeng          = ls_incid-cantidad
                             observacion    = ls_incid-observacion
                             tipo_excepcion = ls_incid-tipo_excepcion
                             cod_motivo     = ls_incid-codigo_motivo
                             des_motivo     = ls_incid-descripcion_motivo
                             fecha_emision  = lv_date "iv_date
                             hora_emision   = lv_hours "iv_hours
                             estatus         = ls_inc_desp-estatus
                             aenam          = sy-uname
                             aedat          = sy-datum
                             aezet          = sy-uzeit ).

      IF lv_check EQ abap_true.
        INSERT zsd_incid_desp FROM ls_inc_desp.
      ENDIF.

      IF sy-subrc NE 0.
        lv_check = abap_false.
      ENDIF.

      IF lv_check NE abap_true.
        lv_status_code =  422.
        lv_reason = 'No se guardaron los documentos de incidentes'.
*        es_incid-observacion = 'Error al tratar de guardar la data'.

        ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |No se guardo el documento|
            detail = |El número de documento { ls_incid-tipo_documento }-{ ls_incid-numero_documento } no se pudo guardar| ).

        APPEND ls_resp_item TO et_resp_list.

        lv_error = lv_error + 1.
        lv_check = abap_false.
      ELSE.
*        IF lv_check EQ abap_true.
        lv_status_code = 200.
        lv_reason = 'OK'.

        ls_resp_item = VALUE #(
              code = |{ lv_reason }-{ lv_status_code }|
              title = |Guardado con éxito|
              detail = |El número de documento { ls_incid-numero_documento } posición { lv_posnr } se guardo con exito| ).

        APPEND ls_resp_item TO et_resp_list.
*        lv_error = lv_error + 1.
*        ENDIF.
      ENDIF.

      lv_posnr = lv_posnr + 10.

    ENDLOOP.

    IF lv_error EQ 0 AND
       lv_check EQ abap_true.
      commit_work( ).

      lv_status_code = 200.
      lv_reason = 'OK'.

      rv_return = abap_true.
    ELSE.
      roolback_work( ).
    ENDIF.

    ev_code = lv_status_code.
    ev_reason = lv_reason.

  ENDMETHOD.

  METHOD handle_fin_ruta.
    DATA(lo_trans) = NEW lcl_trans( iv_tplst ).

    DATA:
*      ls_response TYPE ty_response,
      lv_data    TYPE string,
*      ls_endruta  TYPE zsd_tb_gck,
      ls_endruta TYPE ty_endruta,
      lt_finruta TYPE tt_enddruta,
      lt_endruta TYPE STANDARD TABLE OF zsd_tb_gck,
      lo_json    TYPE REF TO /ui2/cl_json.

    DATA lo_response TYPE REF TO if_http_response.

    " Crear instancia del parser JSON
    lo_json = NEW /ui2/cl_json( ).

    lo_response = io_server->response.

*    CLEAR ls_response.
    CLEAR: ls_resp, lv_json_message.

    TRY.
        io_server->request->get_cdata( RECEIVING data = lv_json ).

        ls_log = VALUE #(
           tplst   = iv_tplst
           proceso = |IER| "Fin de Ruta
           json    = lv_json ).

        DATA(lo_log) = NEW zcl_sd_desp_log( is_json = ls_log ).

*        "obtener el código de estado y la respuesta
*        io_server->response->get_status(
*          IMPORTING
*            code   = lv_status_code
*            reason = lv_reason ).

        " Deserializar JSON a tabla ABAP
        lo_json->deserialize(
          EXPORTING
            json             = lv_json
          CHANGING
            data             = ls_endruta ). "ls_endruta

        IF lv_json IS INITIAL OR
        ls_endruta IS INITIAL.

          ls_resp_item = VALUE #(
              code = |E-{ lv_status_code }|
              title = |Error de Lectura del JSON|
              detail = |Fin despacho: JSON vacío o Error en la estructura del JSON| ).

          APPEND ls_resp_item TO lt_resp_list.

          " Armar respuesta
          ls_resp = VALUE #(
              status = lv_status_code
              reason = lv_reason
              fecha = sy-datum
              hora = sy-uzeit
              message = lt_resp_list ).

*          lv_json_message = lo_json->serialize(
*                             EXPORTING
*                               data        = ls_resp
*                               pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

          zcl_json_utility=>convert_stuct_to_json(
            EXPORTING
                im_s_data = ls_resp
                im_v_case = zcl_json_utility=>co_ftype_camelcase
            RECEIVING
                rt_v_json = lv_json_message ).

          send_json( iv_response = io_server->response
                    iv_data      = lv_json_message
                    iv_code      = lv_status_code ).

          RETURN.
        ENDIF.

      CATCH cx_root INTO DATA(lx_err).
        rv_response = lx_err->get_text( ).
        lo_response->set_status( code = 500 reason = 'Server Error' ).
        lo_response->set_cdata( lx_err->get_text( ) ).
    ENDTRY.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = ls_endruta-nrodocumento
      IMPORTING
        output = ls_endruta-nrodocumento.

    lo_trans->save_end_ruta(
             EXPORTING
               is_findesp = ls_endruta
             IMPORTING
               ev_json    = lv_json_message
               ev_code    = lv_status_code
               ev_reason  = lv_reason
             CHANGING
               et_resp_list = lt_resp_list ).

    " Armar respuesta
    ls_resp = VALUE #(
        status = lv_status_code
        reason = lv_reason
        tdocumento = ls_endruta-tdocumento
        nrodocumento = ls_endruta-nrodocumento
        fecha = sy-datum
        hora = sy-uzeit
        message = lt_resp_list ).

    zcl_json_utility=>convert_stuct_to_json(
        EXPORTING
            im_s_data = ls_resp
            im_v_case = zcl_json_utility=>co_ftype_camelcase
        RECEIVING
            rt_v_json = lv_json_message ).

    send_json( iv_response = io_server->response
               iv_code     = lv_status_code
               iv_reason   = lv_reason
               iv_data     = lv_json_message ).

    lo_log->save_tracking(
      EXPORTING
          iv_tplst     = iv_tplst
          is_resp_ino  = ls_resp ).

  ENDMETHOD.

  METHOD constructor.

*    IF sy-sysid EQ lc_sistema.
*      ms_amb = VALUE #(
*          sysid = sy-sysid
*          url = |https://qacorimon.innovologistic.innovosite.com/api/v1/integrations|
*          api_key = |l8UIhsE9OJWFpmgFSHzbTsFTBsexPLFpSwYJAdSv| ).
*    ELSE.
*      ms_amb = VALUE #(
*         sysid = sy-sysid
*         url = |https://corimon.innovologistic.innovosite.com/api/v1/integrations|
*         api_key = |l8UIhsE9OJWFpmgFSHzbTsFTBsexPLFpSwYJAdSv| ).

*    ENDIF.

  ENDMETHOD.

  METHOD handle_ini_or.
    DATA(lo_trans) = NEW lcl_trans( iv_tplst ).

    DATA:
      lv_data TYPE string,
      ls_ruta TYPE ty_endruta,
      lt_ruta TYPE tt_enddruta,
      lt_gck  TYPE STANDARD TABLE OF zsd_tb_gck,
      lo_json TYPE REF TO /ui2/cl_json.

    DATA lo_response TYPE REF TO if_http_response.

    " Crear instancia del parser JSON
    lo_json = NEW /ui2/cl_json( ).

    lo_response = io_server->response.

*    CLEAR ls_response.
    CLEAR: ls_resp, lv_json_message.

    TRY.
        io_server->request->get_cdata( RECEIVING data = lv_json ).

        ls_log = VALUE #(
           tplst   = iv_tplst
           proceso = |IIOR| "Innovo Inicio de Orden de Retiro
           json    = lv_json ).

        DATA(lo_log) = NEW zcl_sd_desp_log( is_json = ls_log ).

        " Deserializar JSON a tabla ABAP
        lo_json->deserialize(
          EXPORTING
            json             = lv_json
          CHANGING
            data             = ls_ruta ). "ls_endruta

        IF lv_json IS INITIAL OR
        ls_ruta IS INITIAL.

          ls_resp_item = VALUE #(
              code = |E-{ lv_status_code }|
              title = |Error de Lectura del JSON|
              detail = |Inicio de despacho OR: JSON vacío o Error en la estructura del JSON| ).

          APPEND ls_resp_item TO lt_resp_list.

          " Armar respuesta
          ls_resp = VALUE #(
              status = lv_status_code
              reason = lv_reason
              fecha = sy-datum
              hora = sy-uzeit
              message = lt_resp_list ).

          zcl_json_utility=>convert_stuct_to_json(
            EXPORTING
                im_s_data = ls_resp
                im_v_case = zcl_json_utility=>co_ftype_camelcase
            RECEIVING
                rt_v_json = lv_json_message ).

          send_json( iv_response = io_server->response
                     iv_data      = lv_json_message
                     iv_code      = lv_status_code ).

          RETURN.
        ENDIF.

      CATCH cx_root INTO DATA(lx_err).
        rv_response = lx_err->get_text( ).
        lo_response->set_status( code = 500 reason = 'Server Error' ).
        lo_response->set_cdata( lx_err->get_text( ) ).
    ENDTRY.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = ls_ruta-nrodocumento
      IMPORTING
        output = ls_ruta-nrodocumento.

    lo_trans->save_ini_ruta_or(
             EXPORTING
               is_desp = ls_ruta
             IMPORTING
               ev_json    = lv_json_message
               ev_code    = lv_status_code
               ev_reason  = lv_reason
             CHANGING
               et_resp_list = lt_resp_list ).

    " Armar respuesta
    ls_resp = VALUE #(
        status = lv_status_code
        reason = lv_reason
        tdocumento = 'GD'
        nrodocumento = ls_ruta-nrodocumento
        fecha = sy-datum
        hora = sy-uzeit
        message = lt_resp_list ).

    zcl_json_utility=>convert_stuct_to_json(
        EXPORTING
            im_s_data = ls_resp
            im_v_case = zcl_json_utility=>co_ftype_camelcase
        RECEIVING
            rt_v_json = lv_json_message ).

    send_json( iv_response = io_server->response
               iv_code     = lv_status_code
               iv_reason   = lv_reason
               iv_data     = lv_json_message ).

    lo_log->save_tracking(
      EXPORTING
          iv_tplst     = iv_tplst
          is_resp_ino  = ls_resp ).

  ENDMETHOD.

ENDCLASS.
