CLASS zcl_sd_romana DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_extension.
  PROTECTED SECTION.
  PRIVATE SECTION.

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

      BEGIN OF ty_response_item,
        code   TYPE string,
        title  TYPE string,
        detail TYPE string,
*        fecha  TYPE datum,
*        hora   TYPE sy-uzeit,
      END OF ty_response_item,

      tt_response_list TYPE STANDARD TABLE OF ty_response_item WITH EMPTY KEY,

      BEGIN OF ty_response,
        status  TYPE i,
        reason  TYPE string,
        tdocu   TYPE char3,
        numguia TYPE i,
        fecha   TYPE datum,
        hora    TYPE sy-uzeit,
        message TYPE tt_response_list,
      END OF ty_response,

      tt_response TYPE ty_response,

      BEGIN OF ty_pesaje,
        peso_tara  TYPE i,
        hora_tara  TYPE string, "timestamp,
        peso_bruto TYPE i,
        hora_bruto TYPE string, "timestamp,
        peso_neto  TYPE i,
        diferencia TYPE i,
      END OF ty_pesaje,

      BEGIN OF ty_transporte,
        numguia             TYPE tknum,
        nacionalidad        TYPE c LENGTH 1,
        cedula              TYPE zciconductor,
        empresa             TYPE zname1,
        placa               TYPE zplvehiculo,
        marca               TYPE zzvehiculo,
        modelo              TYPE ztipovehiculo,
        numero_pase         TYPE i,
        motivo              TYPE zmotivo,
        hora_salida_planta  TYPE string, "timestamp,
        hora_entrada_planta TYPE string, "timestamp,
        datos_pesaje        TYPE STANDARD TABLE OF ty_pesaje
            WITH EMPTY KEY,
      END OF ty_transporte,

      tt_transporte TYPE STANDARD TABLE OF ty_transporte,

*      BEGIN OF ty_conductor,
*        cedula         TYPE zciconductor,
*        email          TYPE zcorreo,
*        exp_licencia   TYPE dats,
*        exp_salud      TYPE dats,
*        nombre         TYPE zconductor,
*        rif            TYPE stcd1,
*        telf           TYPE telf1,
*        emp_transporte TYPE zname1,
*      END OF ty_conductor,

*      BEGIN OF ty_conductor,
*        nacionalidad TYPE z_nacionalidad,
*        cedula       TYPE zciconductor,
*        email        TYPE zcorreo,
*        exp_licencia TYPE dats,
*        exp_salud    TYPE dats,
*        nombre       TYPE zconductor,
*        apellido     TYPE zconductor,
*        rif          TYPE stcd1,
*        telefono     TYPE telf1,
*        transporte   TYPE zname1,
*        activo       TYPE zsd_status_activo,
*      END OF ty_conductor,
*
*      tt_conductor TYPE STANDARD TABLE OF ty_conductor
*                     WITH NON-UNIQUE KEY cedula,

*      BEGIN OF ty_json,
*        id(3) TYPE c,
*        json  TYPE string,
*      END OF ty_json,

      BEGIN OF ty_json_i,
        id   TYPE i,
        json TYPE string,
      END OF ty_json_i,

      BEGIN OF ty_log,
        tplst   TYPE tplst,
        proceso TYPE char3,
        json    TYPE string,
      END OF ty_log,

      tt_log TYPE STANDARD TABLE OF ty_log.
*
*      BEGIN OF ty_desp,
*        gc   TYPE string,
*        fac  TYPE string,
*        oe   TYPE string,
*        desp TYPE string,
*      END OF ty_desp.

    DATA: lt_errors     TYPE ty_error_list,
          ls_error_item TYPE ty_error_item,
          ls_error_resp TYPE ty_error_response,
          ls_log        TYPE ty_log.

    DATA:
      lt_resp_list TYPE tt_response_list,
      ls_resp_item TYPE ty_response_item,
      ls_resp      TYPE ty_response.

    DATA: lv_status_code  TYPE i VALUE 400, " Código HTTP
          lv_reason       TYPE string VALUE 'Bad Request',
          lv_json_error   TYPE string,
          lv_json_message TYPE string.
*
*    DATA request TYPE REF TO if_http_request.

    METHODS:
*      handle_get_conductor
*        IMPORTING
*          io_server TYPE REF TO if_http_server,

      handle_get
        IMPORTING
          iv_request  TYPE REF TO if_http_request
          iv_response TYPE REF TO if_http_response,
*        EXPORTING es_guia     TYPE ty_guia,

      handle_conductor
        IMPORTING
          io_server TYPE REF TO if_http_server
          iv_tplst  TYPE tplst,

      handle_post
        IMPORTING
          io_server TYPE REF TO if_http_server,

*      handle_post_conductor
*        IMPORTING
*          io_server TYPE REF TO if_http_server,

      handle_entrada_transp
        IMPORTING
          io_server TYPE REF TO if_http_server
          iv_tplst  TYPE tplst,

      handle_llegada_transp
        IMPORTING
          io_server TYPE REF TO if_http_server
          iv_tplst  TYPE tplst,

      handle_salida_transp
        IMPORTING
          io_server TYPE REF TO if_http_server
          iv_tplst  TYPE tplst,

      handle_pesada_romana
        IMPORTING
          io_server TYPE REF TO if_http_server
          iv_tplst  TYPE tplst
          iv_romana TYPE char3,

      send_json
        IMPORTING
          iv_response TYPE REF TO if_http_response
          iv_data     TYPE string
          iv_code     TYPE i DEFAULT 200
          iv_reason   TYPE string DEFAULT 'OK',

      send_error
        IMPORTING io_server  TYPE REF TO if_http_server
                  iv_code    TYPE i
                  iv_message TYPE string,

      handle_in_transp_or
        IMPORTING
          io_server TYPE REF TO if_http_server
          iv_tplst  TYPE tplst.
ENDCLASS.

CLASS zcl_sd_romana IMPLEMENTATION.

  METHOD if_http_extension~handle_request.
    DATA:
      lv_path_info      TYPE string,
      lv_request_method TYPE string,
      lv_env(1)         TYPE c,
      lv_socied         TYPE bukrs,
      lv_client         TYPE kunnr.

    TYPES:
*      tt_json   TYPE STANDARD TABLE OF ty_json,
*      tt_json_i TYPE STANDARD TABLE OF ty_json_i,

      BEGIN OF ty_desp,
        gc   TYPE string,
        fac  TYPE string,
        oe   TYPE string,
        desp TYPE string,
      END OF ty_desp.

    DATA:
*      ls_guia   TYPE ty_guia,
      mv_json TYPE string,
      gs_desp TYPE ty_desp.
*      gt_json   TYPE tt_json,
*      gt_json_i TYPE tt_json_i.

    DATA:
      lt_errors     TYPE ty_error_list,
      ls_error_item TYPE ty_error_item,
      ls_error_resp TYPE ty_error_response.

    DATA:
*          lv_method   TYPE string,
      lo_request  TYPE REF TO if_http_request,
      lo_response TYPE REF TO if_http_response,
      lt_json     TYPE string.

    DATA:
      lt_fields      TYPE tihttpnvp,
      ls_inputparams TYPE LINE OF tihttpnvp.

    FIELD-SYMBOLS <fs_param> TYPE LINE OF tihttpnvp.

    CLEAR lt_errors.

*esquema de seguridad alterno (i)
    DATA:
      lt_header_fields TYPE tihttpnvp,
      response         TYPE REF TO if_http_response.
*          ls_header_field  TYPE LINE OF tihttpnvp,
*          lv_text          TYPE string

**    " Obtener objetos request y response
*    lo_request  = server->request.
*    lo_response = server->response.
*    BREAK-POINT.

    CLEAR: ls_resp, ls_resp_item, lt_resp_list.

    TRY.
        DATA(lv_method) = server->request->get_header_field( '~request_method' ).
        DATA(lv_path) = server->request->get_header_field( '~path_info' ).


        READ TABLE lt_fields INTO DATA(ls_fields) INDEX 1.

        TRANSLATE lv_method TO UPPER CASE.

        CASE lv_method.
          WHEN 'GET'.
            CASE lv_path.
              WHEN '/guia_crp'.
*                handle_get_conductor( server ).
*              WHEN '/conductor'.
*                handle_conductor( server ).
            ENDCASE.

          WHEN 'POST'.
            handle_post( server ).

          WHEN OTHERS.
            server->response->get_status(
                IMPORTING
                  code   = lv_status_code
                  reason = lv_reason ).

            ls_resp_item = VALUE #(
                 code = |E{ lv_status_code }|
                 title = |Método no soportado|
*                 fecha = sy-datum
*                 hora = sy-uzeit
                 detail = |El método { lv_path } no existe| ).

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

            send_json( iv_response = server->response
                       iv_code     = lv_status_code
                       iv_data     = lv_json_message ).
            RETURN.
        ENDCASE.

      CATCH cx_root INTO DATA(lx_err).
*        server->response->get_status(
*            IMPORTING
*              code   = lv_status_code
*              reason = lv_reason ).

        ls_resp_item = VALUE #(
           code = |E{ lv_status_code }|
           title = 'Error Interno del servidor'
           detail = |Error: { lx_err->get_text( ) }| ).

*        APPEND ls_error_item TO lt_errors.
        APPEND ls_resp_item TO lt_resp_list.

        " Armar respuesta
        ls_resp = VALUE #(
            status = lv_status_code
            reason = lv_reason
            fecha = sy-datum
            hora = sy-uzeit
            message = lt_resp_list ).

*        ls_error_resp = VALUE #(
*            status = lv_status_code
*            reason = lv_reason
*            errors = lt_errors ).

        lv_json_error = /ui2/cl_json=>serialize(
                           data        = ls_resp
                           pretty_name = /ui2/cl_json=>pretty_mode-low_case
                           compress    = abap_false ).

        send_json( iv_response = server->response
                   iv_data     = lv_json_error
                   iv_code     = lv_status_code ).
        RETURN.
*        send_json( iv_response = lo_response
*                   iv_data     = |error: { lx_err->get_text( ) }|
*                   iv_code     = 500 ).
    ENDTRY.

*    server->request->get_header_fields( CHANGING fields = lt_header_fields[] ).
*    lo_request->get_header_fields( CHANGING fields = lt_header_fields[] ).

*    "Get request info
*    lv_path_info = server->request->get_header_field( name = '~path_info' ).
*    lv_request_method = server->request->get_header_field( name = '~request_method' ).
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
*    IF ls_guia IS INITIAL.
*
*      ls_error_item = VALUE #(
*               code = 'E0003'
*               title = 'Parametros vacíos'
*               detail = |El transporte { ls_guia-tplst } ó la Guía { ls_guia-tknum }| ).
*
*      APPEND ls_error_item TO lt_errors.
*      " Armar respuesta
*      ls_error_resp = VALUE #(
*          status = lv_status_code
*          reason = lv_reason
*          errors = lt_errors ).
*
*      lv_json_error = /ui2/cl_json=>serialize(
*                         data        = ls_error_resp
*                         pretty_name = /ui2/cl_json=>pretty_mode-low_case
*                         compress    = abap_false
*                      ).
*      send_json( iv_response = lo_response
*                 iv_data     = lv_json_error
*                 iv_code     = 422 ).
*
**      lo_response->set_status( code = '500' reason = 'Parametros vacíos' ).
*      RETURN.
*    ENDIF.

*    IF lv_request_method EQ 'GET'.
*      DATA(lo_trans) = NEW zcl_sd_doc_fd( ).
*
*      TRY.
*          lo_trans->init(
*        EXPORTING
*          is_guia               = ls_guia
*        IMPORTING
*          ev_json_gc            = gs_desp-gc
*          ev_json_oe            = gs_desp-oe
*          ev_json_fa            = gs_desp-fac
*          ev_json_desp          = gs_desp-desp
*          et_json               = gt_json_i ).
*        CATCH cx_abap_invalid_value.    "
**      CATCH cx_ INTO cx.
*          CALL METHOD server->response->set_status( code = '500' reason = 'Error interno' ).
*          RETURN.
*      ENDTRY.
*
*      IF gs_desp-desp IS INITIAL.
*        ls_error_item = VALUE #(
*            code = 'E0002'
*            title = 'No hay datos'
*            detail = |No existe la Guía de carga: { ls_guia-tknum }| ).
*
*        APPEND ls_error_item TO lt_errors.
*        " Armar respuesta
*        ls_error_resp = VALUE #(
*            status = lv_status_code
*            reason = lv_reason
*            errors = lt_errors ).
*
*        lv_json_error = /ui2/cl_json=>serialize(
*                           data        = ls_error_resp
*                           pretty_name = /ui2/cl_json=>pretty_mode-low_case
*                           compress    = abap_false
*                        ).
*        send_json( iv_response = lo_response
*                   iv_data     = lv_json_error
*                   iv_code     = 422 ).
**        CALL METHOD lo_response->set_status( code = '422' reason = 'No existe la Guía de carga' ).
**        CALL METHOD lo_response->set_cdata( 'No existe la Guía de carga' ).
*        RETURN.
*      ENDIF.
*
**factura 0097028595
*
*      send_json( iv_response = lo_response
*                 iv_data     = gs_desp-desp ).
*
**      gt_json = VALUE #(
**        ( id = 'GC' json = gs_desp-gc )
**        ( id = 'FAC' json = gs_desp-fac )
**        ( id = 'OE' json = gs_desp-oe ) ).
*
*    ENDIF.

    " Configurar cabeceras HTTP
*    lo_response->set_header_field( name  = 'Content-Type'
*                                   value = 'application/json; charset=utf-8' ).

*    CALL METHOD server->response->set_status( code = 200 reason = 'FIN' ).

    " Enviar el JSON
*    lo_response->set_cdata( lv_json_ser ).

  ENDMETHOD.

  METHOD handle_conductor.
    DATA:
      lv_data TYPE string,
      lv_json TYPE string,
      lv_rif  TYPE lifnr.
*      ls_driver TYPE ty_conductor,
*      lt_driver TYPE tt_conductor.

    DATA: lo_response TYPE REF TO if_http_response.

    DATA(lo_romserv) = NEW zcl_sd_romana_serv( iv_type = 'T'   ).

    DATA:
      ls_driver TYPE lo_romserv->ty_conductor,
      lt_driver TYPE lo_romserv->tt_conductor,
      ls_driv   TYPE zsd_tb_drivers.

    lo_response = io_server->response.

    CLEAR: lv_json_message, lt_driver.

    TRY.
        io_server->request->get_cdata( RECEIVING data = lv_json ).

        ls_log = VALUE #(
           tplst   = iv_tplst
           proceso = |RAC| "Romana Actualizar Conductor
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
            data = ls_driver ).

        IF lv_json IS INITIAL OR
           ls_driver IS INITIAL.

          lv_status_code = 500.
          lv_reason = 'Error interno'.

          ls_resp_item = VALUE #(
                code = |E-{ lv_status_code }|
                title = |Error de Lectura del JSON|
                detail = |JSON vacío o Error en la estructura| ).

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

          send_json( iv_response = io_server->response
                     iv_code     = lv_status_code
                     iv_reason   = lv_reason
                     iv_data     = lv_json_message ).
          RETURN.
        ENDIF.

      CATCH cx_root INTO DATA(lx_err).

        lv_status_code = 500.
        lv_reason = |Error Interno del servidor|.

        ls_error_item = VALUE #(
           code = 'E-0001'
           title = 'Error Interno del servidor'
           detail = |No se pudo enviar el documento { ls_driver-cedula } error: { lx_err->get_text( ) }| ).

        APPEND ls_error_item TO lt_resp_list.
    ENDTRY.

    IF lo_romserv->valid_driver(
     EXPORTING
       is_driver    = ls_driver
     CHANGING
       et_resp_list = lt_resp_list ) EQ abap_true.

      APPEND ls_driver TO lt_driver.

      IF lo_romserv->save_conductores(
            EXPORTING
              it_drivers = lt_driver
              iv_init    = abap_false
            IMPORTING
              et_driver  = ls_driv ) EQ abap_true.

        DATA(lo_roma) = NEW lcl_romana( iv_tplst = iv_tplst ).

        DATA(lo_innovo) = NEW zcl_sd_innovo(
            iv_tknum   = space
            iv_json    = space
            is_amb     = lo_roma->ms_innovo ).

        lv_rif = ls_driver-rif.

        IF lo_innovo->upd_carriers( iv_rif = lv_rif ) EQ abap_false.
          lv_status_code = 422.
          lv_reason = 'No existe'.

          ls_resp_item = VALUE #(
                code = |{ lv_reason }-{ lv_status_code }|
                title = |Error al actualizar|
                detail = |La empresa transportista { ls_driver-rif } no se guardo con exito| ).

          APPEND ls_resp_item TO lt_resp_list.
        ENDIF.

        IF lo_innovo->send_driver( is_driver = ls_driv ) EQ abap_true.
          lv_status_code = 200.
          lv_reason = 'OK'.
          ls_resp_item = VALUE #(
                code = |{ lv_reason }-{ lv_status_code }|
                title = |Guardado con éxito|
                detail = |El conductor: { ls_driver-cedula } se guardo con exito| ).
        ELSE.
          lv_status_code = 422.
          lv_reason = 'Datos invalido'.
          ls_resp_item = VALUE #(
                code = |{ lv_reason }-{ lv_status_code }|
                title = |Error de guardado|
                detail = |El conductor: { ls_driver-cedula } no se guardo con exito| ).
        ENDIF.

        APPEND ls_resp_item TO lt_resp_list.
      ENDIF.

    ENDIF.

    " Armar respuesta
    ls_resp = VALUE #(
        status = lv_status_code
        reason = lv_reason
        tdocu  = ls_log-proceso
        numguia = ls_driver-cedula+1
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
          iv_tplst     = |ROMA|
          is_resp_rom  = ls_resp ).

  ENDMETHOD.

  METHOD handle_get.
*    " Ejemplo: obtener parámetros de la URL
**    es_guia-tplst = iv_request->get_form_field( 'soc' ).
*    es_guia-tplst = 1200.
*    DATA(lv_tknum) = iv_request->get_form_field( 'guia' ).
*
*    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
*      EXPORTING
*        input  = lv_tknum
*      IMPORTING
*        output = es_guia-tknum.
*
**    DATA(json) = |method:GET, param1:{ param1 }, param2:{ param2 }|.
*
**    send_json( iv_response = iv_response iv_data = json ).
*  ENDMETHOD.
*
*
*  METHOD handle_get_conductor.
**    DATA(lv_path) = io_server->request->get_header_field( '~path_info' ).
*
*    DATA: ls_guia TYPE ty_guia,
*          ls_desp TYPE ty_desp.
*
**    CASE lv_path.
**      WHEN '/get_guia_crp'.
*
*    ls_guia-tplst = 1200.
*    DATA(lv_tknum) =  io_server->request->get_form_field( 'guia' ).
*
*    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
*      EXPORTING
*        input  = lv_tknum
*      IMPORTING
*        output = ls_guia-tknum.
*
*    IF ls_guia-tknum IS INITIAL.
*
*      ls_error_item = VALUE #(
*               code = 'E0003'
*               title = 'Parametros vacíos'
*               detail = |la Guía de transporte está vacía| ).
*
*      APPEND ls_error_item TO lt_errors.
*      " Armar respuesta
*      ls_error_resp = VALUE #(
*          status = lv_status_code
*          reason = lv_reason
*          errors = lt_errors ).
*
*      lv_json_error = /ui2/cl_json=>serialize(
*                         data        = ls_error_resp
*                         pretty_name = /ui2/cl_json=>pretty_mode-low_case
*                         compress    = abap_false
*                      ).
*      send_json( iv_response = io_server->response
*                 iv_data     = lv_json_error
*                 iv_code     = 422 ).
*
**      lo_response->set_status( code = '500' reason = 'Parametros vacíos' ).
*      RETURN.
*    ENDIF.
*
*    DATA(lo_trans) = NEW zcl_sd_doc_fd( ).
*
*    TRY.
*        lo_trans->init(
*      EXPORTING
*        is_guia               = ls_guia
*      IMPORTING
*        ev_json_gc            = ls_desp-gc
*        ev_json_oe            = ls_desp-oe
*        ev_json_fa            = ls_desp-fac
*        ev_json_desp          = ls_desp-desp ).
**            et_json               = gt_json_i
*      CATCH cx_abap_invalid_value.    "
**      CATCH cx_ INTO cx.
*        CALL METHOD io_server->response->set_status( code = '500' reason = 'Error interno' ).
*        RETURN.
*    ENDTRY.
*
*    IF ls_desp-desp IS INITIAL.
*      ls_error_item = VALUE #(
*          code = 'E0002'
*          title = 'No hay datos'
*          detail = |Verifique la Guía de transporte: { ls_guia-tknum }| ).
*
*      APPEND ls_error_item TO lt_errors.
*      " Armar respuesta
*      ls_error_resp = VALUE #(
*          status = lv_status_code
*          reason = lv_reason
*          errors = lt_errors ).
*
*      lv_json_error = /ui2/cl_json=>serialize(
*                         data        = ls_error_resp
*                         pretty_name = /ui2/cl_json=>pretty_mode-low_case
*                         compress    = abap_false
*                      ).
*      send_json( iv_response = io_server->response
*                 iv_data     = lv_json_error
*                 iv_code     = 422 ).
*      RETURN.
*    ENDIF.
*
*    send_json( iv_response = io_server->response
*               iv_data     = ls_desp-desp ).
**                   iv_code     = 200 ).
**  WHEN '/get_conductor'.
*
**  WHEN OTHERS.
**    ls_error_item = VALUE #(
**                    code = 'E0003'
**                    title = 'Método GET'
**                    detail = |El método { lv_path } no soportado| ).
**
**    APPEND ls_error_item TO lt_errors.
**    " Armar respuesta
**    ls_error_resp = VALUE #(
**        status = lv_status_code
**        reason = lv_reason
**        errors = lt_errors ).
**
**    lv_json_error = /ui2/cl_json=>serialize(
**                       data        = ls_error_resp
**                       pretty_name = /ui2/cl_json=>pretty_mode-low_case
**                       compress    = abap_false
**                    ).
**    send_json( iv_response = io_server->response
**               iv_data     = lv_json_error
**               iv_code     = 422 ).
**ENDCASE.

  ENDMETHOD.

  METHOD handle_post.
    DATA:
      lt_fields     TYPE tihttpnvp.

    DATA(lv_path) = io_server->request->get_header_field( '~path_info' ).
*    DATA(lo_secure) = NEW zcl_encrypt_api_key( ).

*    DATA: ls_check TYPE lo_secure->ty_valid_secure.

*    ls_check = VALUE #( bukrs = '1200'
*                        servicio = 'POSTMAN'
**                            host = server->request->get_uri
*                        ip = io_server->request->get_header_field( '~remote_addr' )
*                        key = '' ).

    io_server->request->get_header_fields(
      CHANGING
        fields = lt_fields ).

*    READ TABLE lt_fields INTO DATA(ls_fields) INDEX 1.
    CASE lv_path.
      WHEN '/conductor' OR '/transp_crp' OR '/pesada_romana' OR '/in_transp_or_crp'.
*        ls_check = VALUE #(
*              bukrs = '1200'
*              servicio = 'POSTMAN'
*              host = io_server->request->get_header_field( '~remote_host' )
*              ip = io_server->request->get_header_field( '~remote_addr' )
*              key = io_server->request->get_header_field( 'x-api-key' ) ).
    ENDCASE.

*    DATA:
*      ls_guia TYPE ty_guia,
*      ls_desp TYPE ty_desp.

    CASE lv_path.
      WHEN '/conductor'.
*        ls_check = VALUE #( bukrs = '1200'
*                      servicio = 'POSTMAN'
**                            host = server->request->get_uri
*                      ip = io_server->request->get_header_field( '~remote_addr' )
*                      key = io_server->re ).

        handle_conductor(
          EXPORTING
            io_server = io_server
            iv_tplst  = '1200' ).   "( io_server, '1200' ).
*      WHEN '/reg_conductores_crp'.
*        handle_post_conductor( io_server ).
      WHEN '/transp_crp'.
        DATA(lv_romana) = io_server->request->get_form_field( 'romana' ).

        handle_entrada_transp( io_server = io_server iv_tplst  = '1200' ).
      WHEN '/pesada_romana'.
        handle_pesada_romana(
          EXPORTING
            io_server = io_server
            iv_tplst  = '1200'
            iv_romana = 'P' ).
      WHEN '/salida_transp_crp'.
        handle_salida_transp( io_server = io_server iv_tplst  = '1200' ).
      WHEN '/in_transp_or_crp'.
        handle_in_transp_or( io_server = io_server iv_tplst  = '1200' ).
      WHEN OTHERS.

        ls_resp_item = VALUE #(
                code = |E-{ lv_status_code }|
                title = 'Error Método'
                detail = |El método { lv_path } no soportado| ).

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

        send_json( iv_response = io_server->response
                   iv_data     = lv_json_message
                   iv_code     = lv_status_code
                   iv_reason   = lv_reason ).
    ENDCASE.

  ENDMETHOD.

  METHOD send_error.
    io_server->response->set_header_field( name = 'Content-Type'
                                           value = 'application/json' ).
    io_server->response->set_status( code = iv_code reason = iv_message ).

  ENDMETHOD.

  METHOD send_json.
    iv_response->set_content_type( 'application/json' ).
    iv_response->set_header_field( name = 'Content-Type'
                                   value = 'application/json; charset=UTF-8' ).
    iv_response->set_status( code = iv_code reason = lv_reason ).
    iv_response->set_cdata( iv_data ).
  ENDMETHOD.

  METHOD handle_entrada_transp.
    DATA:
      lv_data   TYPE string,
      lv_json   TYPE string,
      ls_transp TYPE ty_transporte,
      ls_stage  TYPE zsd_st_stage.

    DATA: lo_response TYPE REF TO if_http_response.

    lo_response = io_server->response.

    CLEAR lv_json_message.

    TRY.
        io_server->request->get_cdata( RECEIVING data = lv_json ).

        ls_log = VALUE #(
           tplst   = iv_tplst
           proceso = |RET|
           json    = lv_json ).

        DATA(lo_log) = NEW zcl_sd_desp_log( is_json = ls_log ).

        " Deserializar JSON a estructura ABAP
        /ui2/cl_json=>deserialize(
          EXPORTING
            json = lv_json
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING
            data = ls_transp ).

        IF lv_json IS INITIAL OR
           ls_transp IS INITIAL.

          lv_status_code = 500.
          lv_reason = 'Error interno'.

          ls_resp_item = VALUE #(
                code = |E{ lv_status_code }|
                title = |Error de Lectura del JSON|
                detail = |JSON vacío o Error en la estructura| ).

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

          send_json( iv_response = io_server->response
                     iv_code     = lv_status_code
                     iv_reason   = lv_reason
                     iv_data     = lv_json_message ).
          RETURN.
        ENDIF.

      CATCH cx_root INTO DATA(lx_err).
**        lo_response->set_content_type( 'application/json' ).
**        rv_response = lx_err->get_text( ).
**        lo_response->set_status( code = 500 reason = 'Server Error' ).
**        ls_response = VALUE #( id = 500
**                               status = 'Error Servicio'
**                               tdocumento = ls_recep-tdocumento
**                               nrodocumento = ls_recep-nrodocumento
**                               message = 'Error en la estructura del JSON' ).

*        lo_response->set_cdata( lx_err->get_text( ) ).
    ENDTRY.

    DATA(lo_romana) = NEW lcl_romana( iv_tplst ).

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = ls_transp-numguia
      IMPORTING
        output = ls_transp-numguia.

    IF lo_romana->check_transp(
        iv_actividad = 'E'
        iv_tknum = ls_transp-numguia ) EQ abap_false.

      lv_status_code = 404.
      lv_reason = 'Not Found'.

      ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Transporte no existe|
            detail = |El transporte { ls_transp-numguia } no existe| ).

      APPEND ls_resp_item TO lt_resp_list.

    ELSE.

      CLEAR ls_stage.

      IF lo_romana->valid_data(
       EXPORTING
         is_transporte = ls_transp
         iv_actividad  = 'E'
       IMPORTING
         es_stage      = ls_stage
*       es_resp       = es_resp
*         et_resp       = lt_resp_list[]
         CHANGING
         et_resp_list =  lt_resp_list[] ) EQ abap_true.

        CASE ls_stage-tdocumento.
          WHEN 'RXP'.
            DATA(lo_innovo) = NEW zcl_sd_innovo(
                iv_tknum   = space
                iv_json    = space
                is_amb     = lo_romana->ms_innovo ).

            IF lo_innovo->status_stage(
                 EXPORTING is_stage     = ls_stage
                 CHANGING  et_resp_list = lt_resp_list ) EQ abap_false.

              lv_status_code = 422.
              lv_reason = 'Error de datos'.

              ls_resp_item = VALUE #(
                    code = |{ lv_reason }-{ lv_status_code }|
                    title = |Error al actualizar|
                    detail = |No se actualizo el despacho { ls_stage-tknum } al status { ls_stage-sttrg }| ).

              APPEND ls_resp_item TO lt_resp_list.
            ENDIF.

            IF zcl_sd_stat_transp=>update_stage( is_transp = ls_stage ) EQ abap_false.

              lv_status_code = 422.
              lv_reason = 'Error de datos'.

              ls_resp_item = VALUE #(
                    code = |{ lv_reason }-{ lv_status_code }|
                    title = |Error al actualizar|
                    detail = |No se actualizo el despacho { ls_stage-tknum } al status { ls_stage-sttrg }| ).

              APPEND ls_resp_item TO lt_resp_list.

            ENDIF.
          WHEN OTHERS.

            IF lo_romana->load_data(
              EXPORTING
                iv_cedula    = ls_transp-cedula
              IMPORTING
                es_resp_item = ls_resp_item ) EQ abap_false.

              APPEND ls_resp_item TO lt_resp_list.

              lv_status_code = 404.
              lv_reason = 'Not Found'.

              RETURN.
            ENDIF.

        ENDCASE.

        IF lo_romana->save_entrada(
                EXPORTING
                  is_romana  = ls_transp
                IMPORTING
                  ev_code    = lv_status_code
                  ev_reason  = lv_reason
                  ev_json    = lv_data
*          es_resp    = ls_resp
                CHANGING
                  et_resp_list = lt_resp_list[] ) EQ abap_true.

          lo_romana->save_cond_guia(
            EXPORTING
              is_transporte = ls_transp
            CHANGING
              rt_resp_list  = lt_resp_list[]
*            RECEIVING
*              rv_return     = rv_return
          ).

        ENDIF.
      ELSE.
        lv_status_code = 422.
        lv_reason = 'Datos invalidos'.
      ENDIF.

    ENDIF.

    " Armar respuesta
    ls_resp = VALUE #(
        status = lv_status_code
        reason = lv_reason
        tdocu  = ls_log-proceso
        numguia = ls_transp-numguia
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
          is_resp_rom  = ls_resp ).

  ENDMETHOD.

  METHOD handle_salida_transp.
    DATA:
      lv_data   TYPE string,
      lv_json   TYPE string,
      ls_transp TYPE ty_transporte,
      ls_romak  TYPE zsd_tb_romanak,
      ls_stage  TYPE zsd_st_stage.

    DATA: lo_response TYPE REF TO if_http_response.

    lo_response = io_server->response.

    CLEAR lv_json_message.

    TRY.
        io_server->request->get_cdata( RECEIVING data = lv_json ).

        ls_log = VALUE #(
           tplst   = iv_tplst
           proceso = |RST|    "Romana Salida del Transporte
           json    = lv_json ).

        DATA(lo_log) = NEW zcl_sd_desp_log( is_json = ls_log ).

        " Deserializar JSON a estructura ABAP
        /ui2/cl_json=>deserialize(
          EXPORTING
            json = lv_json
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING
            data = ls_transp ).

        IF lv_json IS INITIAL OR
           ls_transp IS INITIAL.

          lv_status_code = 500.
          lv_reason = 'Error interno'.

          ls_resp_item = VALUE #(
                code = |E{ lv_status_code }|
                title = |Error de Lectura del JSON|
                detail = |JSON vacío o Error en la estructura| ).

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
          RETURN.
        ENDIF.

      CATCH cx_root INTO DATA(lx_err).
**        lo_response->set_content_type( 'application/json' ).
**        rv_response = lx_err->get_text( ).
**        lo_response->set_status( code = 500 reason = 'Server Error' ).
**        ls_response = VALUE #( id = 500
**                               status = 'Error Servicio'
**                               tdocumento = ls_recep-tdocumento
**                               nrodocumento = ls_recep-nrodocumento
**                               message = 'Error en la estructura del JSON' ).

*        lo_response->set_cdata( lx_err->get_text( ) ).
    ENDTRY.

    DATA(lo_romana) = NEW lcl_romana( iv_tplst ).

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = ls_transp-numguia
      IMPORTING
        output = ls_transp-numguia.

    IF lo_romana->check_transp(
        iv_actividad = 'S'
        iv_tknum = ls_transp-numguia ) EQ abap_false.

      lv_status_code = 404.
      lv_reason = 'Not Found'.

      ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Transporte no existe|
            detail = |El transporte { ls_transp-numguia } no existe| ).

      APPEND ls_resp_item TO lt_resp_list.

    ELSE.

*      IF lo_romana->load_data(
*        EXPORTING
*          iv_cedula    = ls_transp-cedula
*        IMPORTING
*          es_resp_item = ls_resp_item ) EQ abap_false.
*
*        APPEND ls_resp_item TO lt_resp_list.
*
*        lv_status_code = 404.
*        lv_reason = 'Not Found'.
*
*      ENDIF.

      CLEAR ls_stage.

      IF lo_romana->valid_data(
       EXPORTING
         is_transporte = ls_transp
         iv_actividad = 'S'
       IMPORTING
         es_stage      = ls_stage
*       es_resp       = es_resp
*         et_resp       = lt_resp_list[]
         CHANGING
         et_resp_list =  lt_resp_list[] ) EQ abap_true.

        CASE ls_stage-tdocumento.
          WHEN 'RXP'.
            DATA(lo_innovo) = NEW zcl_sd_innovo(
                iv_tknum   = space
                iv_json    = space
                is_amb     = lo_romana->ms_innovo ).

            IF lo_innovo->status_stage(
                 EXPORTING is_stage     = ls_stage
                 CHANGING  et_resp_list = lt_resp_list ) EQ abap_false.

              lv_status_code = 422.
              lv_reason = 'Error de datos'.

              ls_resp_item = VALUE #(
                    code = |{ lv_reason }-{ lv_status_code }|
                    title = |Error al actualizar|
                    detail = |No se actualizo el despacho { ls_stage-tknum } al status { ls_stage-sttrg }| ).

              APPEND ls_resp_item TO lt_resp_list.
            ENDIF.

            IF zcl_sd_stat_transp=>update_stage( is_transp = ls_stage ) EQ abap_false.

              lv_status_code = 422.
              lv_reason = 'Error de datos'.

              ls_resp_item = VALUE #(
                    code = |{ lv_reason }-{ lv_status_code }|
                    title = |Error al actualizar|
                    detail = |No se actualizo el despacho { ls_stage-tknum } al status { ls_stage-sttrg }| ).

              APPEND ls_resp_item TO lt_resp_list.

            ENDIF.

            IF lo_romana->save_salida(
              EXPORTING
                is_romana    = ls_transp
              IMPORTING
                ev_code      = lv_status_code
                ev_reason    = lv_reason
                es_romak     = ls_romak
*             ev_json      = ev_json
*             es_resp      = es_resp
              CHANGING
                et_resp_list = lt_resp_list[] ) EQ abap_false.

              lv_status_code = 422.
              lv_reason = 'Datos invalidos'.

              ls_resp_item = VALUE #(
                    code = |{ lv_reason }-{ lv_status_code }|
                    title = |Error al actualizar|
                    detail = |No se actualizo la salida del despacho { ls_stage-tknum } de la Romana| ).

              APPEND ls_resp_item TO lt_resp_list.

            ENDIF.

          WHEN OTHERS.

            IF lo_romana->save_salida(
              EXPORTING
                is_romana    = ls_transp
              IMPORTING
                ev_code      = lv_status_code
                ev_reason    = lv_reason
                es_romak     = ls_romak
*             ev_json      = ev_json
*             es_resp      = es_resp
              CHANGING
                et_resp_list = lt_resp_list[] ) EQ abap_true.

              IF lo_romana->send_salida_transp(
                          EXPORTING
                            is_romak     = ls_romak
                          CHANGING
                            et_resp_list = lt_resp_list[] ) EQ abap_true.

*            lo_romana->upd_guia(
*              EXPORTING
*                is_romak     = ls_romak
*              CHANGING
*                et_resp_list = lt_resp_list[]
**                          RECEIVING
**                            rv_return    = rv_return
*            ).
              ELSE.
                lv_status_code = 422.
                lv_reason = 'Datos invalidos'.
              ENDIF.
            ELSE.
              lv_status_code = 422.
              lv_reason = 'Datos invalidos'.
            ENDIF.

        ENDCASE.
      ELSE.
        lv_status_code = 422.
        lv_reason = 'Datos invalidos'.
      ENDIF.
    ENDIF.

    " Armar respuesta
    ls_resp = VALUE #(
        status = lv_status_code
        reason = lv_reason
        tdocu  = ls_log-proceso
        numguia = ls_transp-numguia
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
         is_resp_rom  = ls_resp ).

  ENDMETHOD.

  METHOD handle_pesada_romana.
    DATA:
      lv_data   TYPE string,
      lv_json   TYPE string,
      ls_transp TYPE ty_transporte,
      ls_romp   TYPE zsd_tb_romanap.

*    DATA: lo_response TYPE REF TO if_http_response.

*    lo_response = io_server->response.

    CLEAR lv_json_message.

    TRY.
        io_server->request->get_cdata( RECEIVING data = lv_json ).

        ls_log = VALUE #(
            tplst   = iv_tplst
            proceso = |RPE|
            json    = lv_json ).

        DATA(lo_log) = NEW zcl_sd_desp_log( is_json = ls_log ).

        " Deserializar JSON a estructura ABAP
        /ui2/cl_json=>deserialize(
          EXPORTING
            json = lv_json
*            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING
            data = ls_transp ).

        IF lv_json IS INITIAL OR
           ls_transp IS INITIAL.

          lv_status_code = 500.
          lv_reason = 'Error interno'.

          ls_resp_item = VALUE #(
                code = |E{ lv_status_code }|
                title = |Error de Lectura del JSON|
                detail = |JSON vacío o Error en la estructura| ).

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

          send_json( iv_response = io_server->response
                     iv_code     = lv_status_code
                     iv_reason   = lv_reason
                     iv_data     = lv_json_message ).
          RETURN.
        ENDIF.

      CATCH cx_root INTO DATA(lx_err).
**        lo_response->set_content_type( 'application/json' ).
**        rv_response = lx_err->get_text( ).
**        lo_response->set_status( code = 500 reason = 'Server Error' ).
**        ls_response = VALUE #( id = 500
**                               status = 'Error Servicio'
**                               tdocumento = ls_recep-tdocumento
**                               nrodocumento = ls_recep-nrodocumento
**                               message = 'Error en la estructura del JSON' ).

*        lo_response->set_cdata( lx_err->get_text( ) ).
        lv_status_code = 500.
        lv_reason = 'Error interno'.

        ls_resp_item = VALUE #(
              code = |E{ 500 }|
              title = |Error interno|
              detail = |Error de respuesta del servivio| ).

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

    ENDTRY.

    DATA(lo_romana) = NEW lcl_romana( iv_tplst ).

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = ls_transp-numguia
      IMPORTING
        output = ls_transp-numguia.

    IF lo_romana->check_transp(
        iv_actividad = iv_romana
        iv_tknum = ls_transp-numguia ) EQ abap_false.

      lv_status_code = 404.
      lv_reason = 'Not Found'.

      ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Transporte no existe|
            detail = |El transporte { ls_transp-numguia } no existe| ).

      APPEND ls_resp_item TO lt_resp_list.
    ELSE.

      IF lo_romana->valid_pesada(
        EXPORTING
          is_transporte = ls_transp
        CHANGING
          es_pesaje     = ls_romp
          et_resp_list  = lt_resp_list ) EQ abap_true.

        IF lo_romana->save_pesaje(
            EXPORTING
              is_romana    = ls_transp
              is_pesaje    = ls_romp
            IMPORTING
              ev_code      = lv_status_code
              ev_reason    = lv_reason
*              ev_json      = ev_json
            CHANGING
              et_resp_list = lt_resp_list ) EQ abap_true.

          lo_romana->save_pesaje_guia(
            EXPORTING
              is_transporte = ls_transp
              is_pesaje     = ls_romp
            CHANGING
              rt_resp_list  = lt_resp_list
*  RECEIVING
*    rv_return     = rv_return
          ).

*          lo_romana->save_cond_guia(
*            EXPORTING
*              is_transporte = ls_transp
*            CHANGING
*              rt_resp_list  = lt_resp_list[]
**            RECEIVING
**              rv_return     = rv_return
*          ).

        ENDIF.
      ELSE.
        lv_status_code = 422.
        lv_reason = 'Datos invalidos'.
      ENDIF.

    ENDIF.

    " Armar respuesta
    ls_resp = VALUE #(
        status = lv_status_code
        reason = lv_reason
        tdocu  = ls_log-proceso
        numguia = ls_transp-numguia
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
        is_resp_rom  = ls_resp ).
  ENDMETHOD.

  METHOD handle_in_transp_or.
    DATA:
      lv_data   TYPE string,
      lv_json   TYPE string,
      ls_transp TYPE ty_transporte.

    DATA: lo_response TYPE REF TO if_http_response.

    lo_response = io_server->response.

    CLEAR lv_json_message.

    TRY.
        io_server->request->get_cdata( RECEIVING data = lv_json ).

        ls_log = VALUE #(
           tplst   = iv_tplst
           proceso = |RET|
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
            data = ls_transp ).

        IF lv_json IS INITIAL OR
           ls_transp IS INITIAL.

          lv_status_code = 500.
          lv_reason = 'Error interno'.

          ls_resp_item = VALUE #(
                code = |E{ lv_status_code }|
                title = |Error de Lectura del JSON|
                detail = |JSON vacío o Error en la estructura| ).

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
          RETURN.
        ENDIF.

*        save_recep(
*          EXPORTING
*            iv_tplst   = '1200'
*            is_recep   = ls_recep
*          IMPORTING
*          ev_code      = lv_status_code
*          ev_reason    = lv_reason
*            ev_message = lv_json_message ).

**        IF save_recep( iv_tplst = '1200' is_recep = ls_recep ) EQ abap_true.
**          ls_response = VALUE #( id = 200
**                                 status = 'OK'
**                                 tdocumento = ls_recep-tdocumento
**                                 nrodocumento = ls_recep-nrodocumento
**                                 message = 'Registro guardado correcto' ).
**          lo_response->set_status( code = 200 reason = 'OK' ).
**        ELSE.
**          ls_response = VALUE #( id = 500
**                                 status = 'ErrorDB'
**                                 tdocumento = ls_recep-tdocumento
**                                 nrodocumento = ls_recep-nrodocumento
**                                 message = 'No se pudo guardar el registro' ).
**          lo_response->set_status( code = 500 reason = 'Error Interno' ).
*        ENDIF.

      CATCH cx_root INTO DATA(lx_err).
**        lo_response->set_content_type( 'application/json' ).
**        rv_response = lx_err->get_text( ).
**        lo_response->set_status( code = 500 reason = 'Server Error' ).
**        ls_response = VALUE #( id = 500
**                               status = 'Error Servicio'
**                               tdocumento = ls_recep-tdocumento
**                               nrodocumento = ls_recep-nrodocumento
**                               message = 'Error en la estructura del JSON' ).

*        lo_response->set_cdata( lx_err->get_text( ) ).
    ENDTRY.

    DATA(lo_romana) = NEW lcl_romana( iv_tplst ).

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = ls_transp-numguia
      IMPORTING
        output = ls_transp-numguia.

    IF lo_romana->check_transp(
        iv_actividad = 'E'
        iv_tknum = ls_transp-numguia ) EQ abap_false.

      lv_status_code = 404.
      lv_reason = 'Not Found'.

      ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Transporte no existe|
            detail = |El transporte { ls_transp-numguia } no existe| ).

      APPEND ls_resp_item TO lt_resp_list.

    ELSE.

      IF lo_romana->load_data(
        EXPORTING
          iv_cedula    = ls_transp-cedula
        IMPORTING
          es_resp_item = ls_resp_item ) EQ abap_false.

        APPEND ls_resp_item TO lt_resp_list.

        lv_status_code = 404.
        lv_reason = 'Not Found'.

      ENDIF.

      IF lo_romana->valid_data(
       EXPORTING
         is_transporte = ls_transp
         iv_actividad  = 'E'
*       IMPORTING
*       es_resp       = es_resp
*         et_resp       = lt_resp_list[]
         CHANGING
         et_resp_list =  lt_resp_list[] ) EQ abap_true.

        IF lo_romana->save_entrada(
                EXPORTING
                  is_romana  = ls_transp
                IMPORTING
                  ev_code    = lv_status_code
                  ev_reason  = lv_reason
                  ev_json    = lv_data
*          es_resp    = ls_resp
                CHANGING
                  et_resp_list = lt_resp_list[] ) EQ abap_true.

          lo_romana->save_cond_guia(
            EXPORTING
              is_transporte = ls_transp
            CHANGING
              rt_resp_list  = lt_resp_list[]
*            RECEIVING
*              rv_return     = rv_return
          ).
*          ( is_transporte = is_transporte ).
*          ( is_transporte = ls_transp ).

        ENDIF.
      ELSE.
        lv_status_code = 422.
        lv_reason = 'Datos invalidos'.
      ENDIF.

    ENDIF.

*    " Devolver respuesta en JSON
*    lo_response->set_content_type( 'application/json' ).
*    lo_response->set_cdata( /ui2/cl_json=>serialize( data = ls_response ) ).

    " Armar respuesta
    ls_resp = VALUE #(
        status = lv_status_code
        reason = lv_reason
        tdocu  = ls_log-proceso
        numguia = ls_transp-numguia
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
          is_resp_rom  = ls_resp ).

  ENDMETHOD.

  METHOD handle_llegada_transp.
    DATA:
      lv_data   TYPE string,
      lv_json   TYPE string,
      ls_transp TYPE ty_transporte.

    DATA: lo_response TYPE REF TO if_http_response.

    lo_response = io_server->response.

    CLEAR lv_json_message.

    TRY.
        io_server->request->get_cdata( RECEIVING data = lv_json ).

        ls_log = VALUE #(
           tplst   = iv_tplst
           proceso = |RLT|   "Llegada de Transporte Ordenes de Retiro
           json    = lv_json ).

        DATA(lo_log) = NEW zcl_sd_desp_log( is_json = ls_log ).

        " Deserializar JSON a estructura ABAP
        /ui2/cl_json=>deserialize(
          EXPORTING
            json = lv_json
            pretty_name = /ui2/cl_json=>pretty_mode-camel_case
          CHANGING
            data = ls_transp ).

        IF lv_json IS INITIAL OR
           ls_transp IS INITIAL.

          lv_status_code = 500.
          lv_reason = 'Error interno'.

          ls_resp_item = VALUE #(
                code = |E{ lv_status_code }|
                title = |Error de Lectura del JSON|
                detail = |JSON vacío o Error en la estructura| ).

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

          send_json( iv_response = io_server->response
                     iv_code     = lv_status_code
                     iv_reason   = lv_reason
                     iv_data     = lv_json_message ).
          RETURN.
        ENDIF.

      CATCH cx_root INTO DATA(lx_err).
**        lo_response->set_content_type( 'application/json' ).
**        rv_response = lx_err->get_text( ).
**        lo_response->set_status( code = 500 reason = 'Server Error' ).
**        ls_response = VALUE #( id = 500
**                               status = 'Error Servicio'
**                               tdocumento = ls_recep-tdocumento
**                               nrodocumento = ls_recep-nrodocumento
**                               message = 'Error en la estructura del JSON' ).

*        lo_response->set_cdata( lx_err->get_text( ) ).
    ENDTRY.

    DATA(lo_romana) = NEW lcl_romana( iv_tplst ).

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = ls_transp-numguia
      IMPORTING
        output = ls_transp-numguia.

    IF lo_romana->check_transp(
        iv_actividad = 'OR'
        iv_tknum = ls_transp-numguia ) EQ abap_false.

      lv_status_code = 404.
      lv_reason = 'Not Found'.

      ls_resp_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Transporte no existe|
            detail = |El transporte { ls_transp-numguia } no existe| ).

      APPEND ls_resp_item TO lt_resp_list.

    ELSE.

*      IF lo_romana->load_data(
*        EXPORTING
*          iv_cedula    = ls_transp-cedula
*        IMPORTING
*          es_resp_item = ls_resp_item ) EQ abap_false.
*
*        APPEND ls_resp_item TO lt_resp_list.
*
*        lv_status_code = 404.
*        lv_reason = 'Not Found'.
*
*      ENDIF.

      IF lo_romana->valid_data(
       EXPORTING
         is_transporte = ls_transp
         iv_actividad  = 'EE'

         CHANGING
         et_resp_list =  lt_resp_list[] ) EQ abap_true.

        IF lo_romana->save_entrada(
                EXPORTING
                  is_romana  = ls_transp
                IMPORTING
                  ev_code    = lv_status_code
                  ev_reason  = lv_reason
                  ev_json    = lv_data

                CHANGING
                  et_resp_list = lt_resp_list[] ) EQ abap_true.

          lo_romana->save_cond_guia(
            EXPORTING
              is_transporte = ls_transp
            CHANGING
              rt_resp_list  = lt_resp_list[]
*            RECEIVING
*              rv_return     = rv_return
          ).

        ENDIF.
      ELSE.
        lv_status_code = 422.
        lv_reason = 'Datos invalidos'.
      ENDIF.

    ENDIF.

    " Armar respuesta
    ls_resp = VALUE #(
        status = lv_status_code
        reason = lv_reason
        tdocu  = ls_log-proceso
        numguia = ls_transp-numguia
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
          is_resp_rom  = ls_resp ).

  ENDMETHOD.

ENDCLASS.
