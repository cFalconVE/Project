CLASS lcl_servicios DEFINITION.

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
      ms_amb     TYPE zsd_st_serv_url READ-ONLY,
      mv_display TYPE abap_bool READ-ONLY,
      mv_type    TYPE c1 READ-ONLY.

    METHODS:
      constructor
        IMPORTING
          is_amb     TYPE zsd_st_serv_url "ty_ambiente
          iv_type    TYPE c1 OPTIONAL
          iv_display TYPE abap_bool OPTIONAL,

      post_carriers
        IMPORTING
          iv_rif           TYPE lifnr OPTIONAL
*          iv_type          TYPE c1 OPTIONAL
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      post_drivers
        RETURNING VALUE(rv_return) TYPE abap_bool,

      send_driver
        IMPORTING
          is_driver        TYPE zsd_tb_drivers
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      send_despacho
        IMPORTING
          iv_tknum         TYPE tknum
          iv_json          TYPE string
          iv_mostrar       TYPE abap_bool OPTIONAL
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      exit_despacho
        IMPORTING
*        iv_tkum          TYPE tknum
          is_transp        TYPE zsd_tb_romanak
        CHANGING
          et_resp_list     TYPE tt_response_list
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      update_stage
        IMPORTING
          is_stage         TYPE zsd_st_stage
        CHANGING
          et_resp_list     TYPE tt_response_list
        RETURNING
          VALUE(rv_return) TYPE abap_bool.

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

      BEGIN OF ty_stat_exit,
        tknum        TYPE tknum,
        fecha_salida TYPE z_fec_sal,
        hora_salida  TYPE z_hora_sal,
      END OF ty_stat_exit.

    DATA: lt_errors     TYPE ty_error_list,
          ls_error_item TYPE ty_error_item,
          ls_error_resp TYPE ty_error_response.

    DATA:
      lo_client      TYPE REF TO if_http_client,
      lo_response    TYPE REF TO if_http_response,
      lv_response    TYPE string,
*      ls_json_sta    TYPE zsd_st_json_status,
*      ls_tb_json_sta TYPE zsd_tb_json_stat,
      lv_status_code TYPE i,
      lv_code        TYPE string,
      lv_json        TYPE string,
      lv_reason      TYPE string.

    METHODS:
      list_drivers
        IMPORTING
          iv_filial  TYPE tplst OPTIONAL
        EXPORTING
          et_drivers TYPE zsd_tt_transporte,

      save_despacho
        IMPORTING
          iv_tknum         TYPE tknum
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      save_exit
        IMPORTING
*          iv_tknum         TYPE tknum
          is_desp_exit     TYPE ty_stat_exit
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      commit_work,

      upd_stat_exit
        IMPORTING
          is_romak         TYPE ty_stat_exit
        CHANGING
          et_resp_list     TYPE tt_response_list
        RETURNING
          VALUE(rv_return) TYPE abap_bool.

ENDCLASS.

CLASS lcl_servicios IMPLEMENTATION.

  METHOD constructor.
    ms_amb = is_amb.
    mv_type = iv_type.
    mv_display = iv_display.
  ENDMETHOD.

  METHOD post_carriers.
    CONSTANTS:
      lc_method TYPE string VALUE 'carriers'.

    DATA:
      lt_drivers TYPE zsd_tt_transporte,
      lv_url     TYPE string.

    DATA(lo_romana) = NEW zcl_sd_romana_serv(
                                iv_transp = abap_true
                                iv_type = mv_type ).

    lo_romana->list_transportes(
        EXPORTING
            iv_rif = iv_rif
            iv_type = mv_type
        IMPORTING
           et_transp = lt_drivers ).
    TRY.
        lv_json = /ui2/cl_json=>serialize(
                 data        = lt_drivers
                 pretty_name = /ui2/cl_json=>pretty_mode-camel_case  " Opcional
                 compress    = abap_false ).

        IF mv_display EQ abap_true.
          cl_demo_output=>display( lv_json ).
        ENDIF.

*        lv_url = |{ mc_url }/{ lc_method }|.
        lv_url = |{ ms_amb-url }/{ lc_method }|.

* crear el cliente http
        CALL METHOD cl_http_client=>create_by_url
          EXPORTING
            url                = lv_url
          IMPORTING
            client             = lo_client
          EXCEPTIONS
            argument_not_found = 1
            plugin_not_active  = 2
            internal_error     = 3
            OTHERS             = 4.

        IF sy-subrc <> 0 OR lo_client IS INITIAL.
          WRITE: 'Error al crear el cliente HTTP'.
          MESSAGE 'Error creando el cliente HTTP' TYPE 'E'.
          RAISE EXCEPTION TYPE cx_sy_no_handler.
*        EXPORTING
*          textid = cx_sy_no_handler=>textid.
          RETURN.
        ENDIF.

        " Establecer cabeceras obligatorias
        lo_client->request->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).

        lo_client->request->set_header_field(
            name  = 'Accept'
            value = 'application/json' ).

        lo_client->request->set_header_field(
            name  = 'x-api-key'
            value = CONV string( ms_amb-api_key ) ).

        lo_client->request->set_header_field(
            name  = 'Authorization'
            value = |Bearer { ms_amb-api_key }| ).
*            value = |Bearer { mc_bearer_token }| ).

        lo_client->request->set_method( 'POST' ).

        lo_client->request->set_cdata( lv_json ).

** enviar la solicitud http get
*        lo_client->send(
*          EXCEPTIONS
*            http_communication_failure = 1
*            http_invalid_state         = 2
*            http_processing_failed     = 3
*            OTHERS                     = 4 ).

        lo_client->send( ).

        IF sy-subrc <> 0.
          WRITE: 'Error al enviar la solicitud HTTP'.
          MESSAGE 'Error al enviar la solicitud HTTP' TYPE 'E'.
        ENDIF.

*        lo_client->receive( ).
        lo_client->receive(
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state         = 2
            http_processing_failed     = 3
            OTHERS                     = 4 ).

*        lo_response = lo_client->response.

*        lv_status_code = lo_response->get_header_field('~status_code').
*        lv_reason = lo_response->get_header_field( '~status_reason' ).
**            lo_client->request->set_content_type( content_type = content_type ).
*
        " Establecer cabeceras obligatorias
        lo_client->response->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).
        "obtener el código de estado y la respuesta
        lo_client->response->get_status(
          IMPORTING
            code   = lv_status_code
            reason = lv_reason ).

        IF lv_status_code EQ '500'.
*          mv_men_1 = 'Certificado ha expirado'.
*          mv_men_2 = 'Por favor comunicarse con TI'.
          WRITE: |Error: { lv_status_code } Mensaje: { lv_reason }|.
*          'Error en el Certificado ó Certificado expirado'.
          MESSAGE |Error: { lv_status_code } Mensaje: { lv_reason }| TYPE 'I'.
        ELSE.
*          mv_men_1 = 'Error al recibir respuesta del HTTP'.
*          CLEAR mv_men_2.
        ENDIF.

*        CHECK lv_status_code EQ '200'.

        lv_response = lo_client->response->get_cdata( ).

        IF mv_display EQ abap_true.
          cl_demo_output=>display( lv_response ).
        ENDIF.

*        " Validación básica si respuesta es válida
*        lo_client->response->get_status( ).
*        IF lo_client->response->get_status( ) = 200.
**          rv_ok = abap_true.
*        ENDIF.

        " Mostrar resultados
*        WRITE: / 'Status:', lv_status_code.
*        WRITE: / 'Respuesta:', lv_response.

*        lv_status_code = lo_response->get_header_field('~status_code').
*        lv_reason = lo_response->get_header_field( '~status_reason' ).

      CATCH cx_http_ext_exception INTO DATA(lx_error).
        WRITE: / 'Error al enviar el JSON:', lx_error->get_text( ).
    ENDTRY.

    " Liberar recursos del cliente HTTP
    IF lo_client IS BOUND.
      lo_client->close( ).
    ENDIF.

    rv_return = abap_true.
  ENDMETHOD.

  METHOD post_drivers.
    CONSTANTS:
      lc_method TYPE string VALUE 'drivers'.

    DATA:
      lt_drivers TYPE zsd_tt_driver_json,
      lv_url     TYPE string.

    DATA(lo_romana) = NEW zcl_sd_romana_serv( iv_lista = abap_false
                                              iv_type = 'T' ).

    lo_romana->list_conductores(
                     IMPORTING
                       et_drivers = lt_drivers ).
    TRY.

*        zcl_json_utility=>convert_stuct_to_json(
*              EXPORTING
*                 im_s_data = lt_drivers
*                 im_v_case = zcl_json_utility=>co_ftype_camelcase "pretty_mode-none
*              RECEIVING
*                 rt_v_json = lv_json ).

        lv_json = /ui2/cl_json=>serialize(
                 data        = lt_drivers
                 pretty_name = /ui2/cl_json=>pretty_mode-none
                 compress    = abap_false ).

        IF mv_display EQ abap_true.
          cl_demo_output=>display( lv_json ).
        ENDIF.

*        lv_url = |{ mc_url }/{ lc_method }|.
        lv_url = |{ ms_amb-url }/{ lc_method }|.

* crear el cliente http
        CALL METHOD cl_http_client=>create_by_url
          EXPORTING
            url                = lv_url
          IMPORTING
            client             = lo_client
          EXCEPTIONS
            argument_not_found = 1
            plugin_not_active  = 2
            internal_error     = 3
            OTHERS             = 4.

        IF sy-subrc <> 0 OR lo_client IS INITIAL.
          WRITE: 'Error al crear el cliente HTTP'.
          MESSAGE 'Error creando el cliente HTTP' TYPE 'E'.
          RAISE EXCEPTION TYPE cx_sy_no_handler.
*        EXPORTING
*          textid = cx_sy_no_handler=>textid.
          RETURN.
        ENDIF.

        " Establecer cabeceras obligatorias
        lo_client->request->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).

        lo_client->request->set_header_field(
            name  = 'Accept'
            value = 'application/json' ).

        lo_client->request->set_header_field(
            name  = 'x-api-key'
            value = CONV string( ms_amb-api_key ) ).

        lo_client->request->set_header_field(
            name  = 'Authorization'
            value = |Bearer { ms_amb-api_key }| ).

        lo_client->request->set_method( 'POST' ).

        lo_client->request->set_cdata( lv_json ).

** enviar la solicitud http get
*        lo_client->send(
*          EXCEPTIONS
*            http_communication_failure = 1
*            http_invalid_state         = 2
*            http_processing_failed     = 3
*            OTHERS                     = 4 ).

        lo_client->send( ).

        IF sy-subrc <> 0.
          WRITE: 'Error al enviar la solicitud HTTP'.
          MESSAGE 'Error al enviar la solicitud HTTP' TYPE 'E'.
        ENDIF.

*        lo_client->receive( ).
        lo_client->receive(
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state         = 2
            http_processing_failed     = 3
            OTHERS                     = 4 ).

*        lo_response = lo_client->response.

*        lv_status_code = lo_response->get_header_field('~status_code').
*        lv_reason = lo_response->get_header_field( '~status_reason' ).
**            lo_client->request->set_content_type( content_type = content_type ).
*
        "obtener el código de estado y la respuesta
        lo_client->response->get_status(
          IMPORTING
            code   = lv_status_code
            reason = lv_reason ).

*        IF lv_status_code EQ '500'.
**          mv_men_1 = 'Certificado ha expirado'.
**          mv_men_2 = 'Por favor comunicarse con TI'.
*          WRITE: |Error: { lv_status_code } Mensaje: { lv_reason }|.
**          'Error en el Certificado ó Certificado expirado'.
*          MESSAGE |Error: { lv_status_code } Mensaje: { lv_reason }| TYPE 'I'.
*        ELSE.
**          mv_men_1 = 'Error al recibir respuesta del HTTP'.
**          CLEAR mv_men_2.
*        ENDIF.

        lo_client->response->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).

        lv_response = lo_client->response->get_cdata( ).

*        cl_demo_output=>display( lv_response ).

        CASE lv_status_code.
          WHEN '200'.
          WHEN '403'.

          WHEN '422'.
            ls_error_item = VALUE #(
                     code = lv_status_code
                     title = 'Registro no procesado'
                     detail = |No se pudo enviar el documento { lv_response }| ).
          WHEN '500'.
            ls_error_item = VALUE #(
                     code = lv_status_code
                     title = 'Error en el certificado SSL o se expiro'
                     detail = |Invalido del certificado SSL| ).
          WHEN OTHERS.
            ls_error_item = VALUE #(
                       code = lv_status_code
                       title = |Error desconocido { lv_status_code }|
                       detail = |detalle: { lv_reason } - { lv_response }| ).
        ENDCASE.

*        ls_error_item = VALUE #(
*                   code = 'e0001'
*                   title = 'Error Interno del servidor'
*                   detail = |No se pudo enviar el documento| ).
*
*        APPEND ls_error_item TO lt_errors.

        ls_error_resp = VALUE #(
            status = lv_status_code
            reason = lv_reason
            errors = lt_errors ).

        DATA(lv_json_error) = /ui2/cl_json=>serialize(
                           data        = ls_error_resp
                           pretty_name = /ui2/cl_json=>pretty_mode-low_case
                           compress    = abap_false ).

        IF mv_display EQ abap_true.
          cl_demo_output=>display( lv_response ).
          cl_demo_output=>display_json( json = lv_json_error ).
        ENDIF.

*        " Validación básica si respuesta es válida
*        lo_client->response->get_status( ).
*        IF lo_client->response->get_status( ) = 200.
**          rv_ok = abap_true.
*        ENDIF.

*        " Mostrar resultados
*        WRITE: / 'Status:', lv_status_code.
*        WRITE: / 'Respuesta:', lv_response.

*        lv_status_code = lo_response->get_header_field('~status_code').
*        lv_reason = lo_response->get_header_field( '~status_reason' ).

      CATCH cx_http_ext_exception INTO DATA(lx_error).
        WRITE: / 'Error al enviar el JSON:', lx_error->get_text( ).
    ENDTRY.

    " Liberar recursos del cliente HTTP
    IF lo_client IS BOUND.
      lo_client->close( ).
    ENDIF.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD list_drivers.

  ENDMETHOD.

  METHOD send_despacho.
    CONSTANTS:
        lc_method TYPE string VALUE 'sap/inbound/dispatch-guide'.

    DATA:
*      lt_drivers TYPE zsd_tt_driver_json,
      lv_url     TYPE string.
*
*    DATA(lo_romana) = NEW zcl_sd_romana_serv( iv_lista = abap_false ).
*
*    lo_romana->list_conductores(
*                     IMPORTING
*                       et_drivers = lt_drivers ).
    TRY.

*        lv_json = /ui2/cl_json=>serialize(
*                 data        = lt_drivers
*                 pretty_name = /ui2/cl_json=>pretty_mode-none
*                 compress    = abap_false ).
*
*        cl_demo_output=>display( lv_json ).

        lv_url = |{ ms_amb-url }/{ lc_method }|.

* crear el cliente http
        CALL METHOD cl_http_client=>create_by_url
          EXPORTING
            url                = lv_url
          IMPORTING
            client             = lo_client
          EXCEPTIONS
            argument_not_found = 1
            plugin_not_active  = 2
            internal_error     = 3
            OTHERS             = 4.

        IF sy-subrc <> 0 OR lo_client IS INITIAL.
          WRITE: 'Error al crear el cliente HTTP'.
          MESSAGE 'Error creando el cliente HTTP' TYPE 'E'.
          RAISE EXCEPTION TYPE cx_sy_no_handler.
*        EXPORTING
*          textid = cx_sy_no_handler=>textid.
          RETURN.
        ENDIF.

        " Establecer cabeceras obligatorias
        lo_client->request->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).

        lo_client->request->set_header_field(
            name  = 'Accept'
            value = 'application/json' ).

        lo_client->request->set_header_field(
            name  = 'x-api-key'
            value = CONV string( ms_amb-api_key ) ).

        lo_client->request->set_header_field(
            name  = 'Authorization'
            value = |Bearer { ms_amb-api_key }| ).

        lo_client->request->set_method( 'POST' ).

        lo_client->request->set_cdata( iv_json ).

        IF mv_display EQ 'X'.
          cl_demo_output=>display( iv_json ).
        ENDIF.

        lo_client->send( ).

        IF sy-subrc <> 0.
          WRITE: 'Error al enviar la solicitud HTTP'.
          MESSAGE 'Error al enviar la solicitud HTTP' TYPE 'E'.
        ENDIF.

        lo_client->receive(
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state         = 2
            http_processing_failed     = 3
            OTHERS                     = 4 ).

        "obtener el código de estado y la respuesta
        lo_client->response->get_status(
          IMPORTING
            code   = lv_status_code
            reason = lv_reason ).

        lo_client->response->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).

        lv_response = lo_client->response->get_cdata( ).

        cl_demo_output=>display( lv_response ).

        DATA lt_string TYPE string_table.
*        APPEND |Planetype:      { planetype  } | TO r_result.
*    APPEND |Maximum Seats:  { seats_max  } | TO r_result.
*    APPEND |Occupied Seats: { seats_occ  } | TO r_result.
*    APPEND |Free Seats:     { seats_free } | TO r_result.
*    APPEND |Ticket Price:   { price CURRENCY = currency } { currency } | TO r_result.

        CASE lv_status_code.
          WHEN '200' OR '201'.
            save_despacho( iv_tknum ).
*          WHEN '207'.
          WHEN '403'.

          WHEN '422'.
            ls_error_item = VALUE #(
                     code = lv_status_code
                     title = 'Registro no procesado'
                     detail = |No se pudo enviar el documento { lv_response }| ).
          WHEN '500'.
            ls_error_item = VALUE #(
                     code = lv_status_code
                     title = 'Error en el certificado SSL o se expiro'
                     detail = |Invalido del certificado SSL| ).
          WHEN OTHERS.
            ls_error_item = VALUE #(
                       code = lv_status_code
                       title = |Error desconocido { lv_status_code }|
                       detail = |detalle: { lv_reason } - { lv_response }| ).
        ENDCASE.

*        ls_error_item = VALUE #(
*                   code = 'e0001'
*                   title = 'Error Interno del servidor'
*                   detail = |No se pudo enviar el documento| ).
*
        APPEND ls_error_item TO lt_errors.

        ls_error_resp = VALUE #(
            status = lv_status_code
            reason = lv_reason
            errors = lt_errors ).

        DATA(lv_json_error) = /ui2/cl_json=>serialize(
                           data        = lt_errors
                           pretty_name = /ui2/cl_json=>pretty_mode-low_case
                           compress    = abap_false ).

        IF iv_mostrar EQ abap_true.
*          cl_demo_output=>display( lv_response ).
          cl_demo_output=>display_json( json = lv_json_error ).
        ENDIF.

      CATCH cx_http_ext_exception INTO DATA(lx_error).
        WRITE: / 'Error al enviar el JSON:', lx_error->get_text( ).
        RETURN.
    ENDTRY.

    " Liberar recursos del cliente HTTP
    IF lo_client IS BOUND.
      lo_client->close( ).
    ENDIF.

    rv_return = abap_true.
  ENDMETHOD.

  METHOD exit_despacho.
    CONSTANTS:
       lc_method TYPE string VALUE 'trips/exit'.

    TYPES:
      BEGIN OF st_travel,
        transport_number TYPE znrodocumento,
        date             TYPE zsd_date,
      END OF st_travel.

    DATA:
*      lt_drivers TYPE zsd_tt_driver_json,
      lv_url    TYPE string,
      ls_travel TYPE st_travel,
      lv_time   TYPE  tims.

    SELECT SINGLE tknum, fecha_salida, hora_salida
          FROM zsd_tb_romanak
          INTO @DATA(ls_guia)
         WHERE tknum EQ @is_transp-tknum.

*    SELECT SINGLE tknum, fec_exit, hora_exit
*      FROM zsd_tb_gck
*      INTO @DATA(ls_guia)
*     WHERE tknum EQ @iv_tkum.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        input  = is_transp-tknum
      IMPORTING
        output = ls_travel-transport_number.

*    ls_travel = VALUE #( transport_number = iv_tkum ).

    WRITE sy-uzeit TO lv_time ENVIRONMENT TIME FORMAT.

    ls_travel-date = |{ ls_guia-fecha_salida+0(4) }-{ ls_guia-fecha_salida+4(2) }-{ ls_guia-fecha_salida+6(2) }|.
    ls_travel-date = |{ ls_travel-date } { ls_guia-hora_salida+0(2) }:{ ls_guia-hora_salida+2(2) }:{ ls_guia-hora_salida+4(2) }|.

    TRY.
        lv_json = /ui2/cl_json=>serialize(
                 data        = ls_travel
                 pretty_name = /ui2/cl_json=>pretty_mode-low_case
                 compress    = abap_false ).

        cl_demo_output=>display( lv_json ).

*        lv_url = |{ mc_url }/{ lc_method }|.
        lv_url = |{ ms_amb-url }/{ lc_method }|.

* crear el cliente http
        CALL METHOD cl_http_client=>create_by_url
          EXPORTING
            url                = lv_url
          IMPORTING
            client             = lo_client
          EXCEPTIONS
            argument_not_found = 1
            plugin_not_active  = 2
            internal_error     = 3
            OTHERS             = 4.

        IF sy-subrc <> 0 OR lo_client IS INITIAL.
          WRITE: 'Error al crear el cliente HTTP'.
          MESSAGE 'Error creando el cliente HTTP' TYPE 'E'.
          RAISE EXCEPTION TYPE cx_sy_no_handler.
*        EXPORTING
*          textid = cx_sy_no_handler=>textid.
          RETURN.
        ENDIF.

        " Establecer cabeceras obligatorias
        lo_client->request->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).

        lo_client->request->set_header_field(
            name  = 'Accept'
            value = 'application/json' ).

        lo_client->request->set_header_field(
            name  = 'x-api-key'
            value = CONV string( ms_amb-api_key ) ).

        lo_client->request->set_header_field(
            name  = 'Authorization'
            value = |Bearer { ms_amb-api_key }| ).

        lo_client->request->set_method( 'POST' ).

        lo_client->request->set_cdata( lv_json ).

        lo_client->send( ).

        IF sy-subrc <> 0.
          WRITE: 'Error al enviar la solicitud HTTP'.
          MESSAGE 'Error al enviar la solicitud HTTP' TYPE 'E'.
        ENDIF.

        lo_client->receive(
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state         = 2
            http_processing_failed     = 3
            OTHERS                     = 4 ).

        "obtener el código de estado y la respuesta
        lo_client->response->get_status(
          IMPORTING
            code   = lv_status_code
            reason = lv_reason ).

        lo_client->response->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).

        lv_response = lo_client->response->get_cdata( ).

*        cl_demo_output=>display( lv_response ).

        CASE lv_status_code.
          WHEN '200' OR '201'.
            ls_error_item = VALUE #(
                       code = lv_status_code
                       title = 'Registro no procesado '
                       detail = |Salida del despacho { lv_response } se realizo con exito (Innovo)| ).
*            rv_return = save_exit( is_desp_exit = ls_guia ).

*            APPEND ls_error_item TO et_resp_list.

            IF save_exit( is_desp_exit = ls_guia ) EQ abap_true.

              APPEND ls_error_item TO et_resp_list.

              ls_error_item = VALUE #(
                    code = lv_status_code
                    title = 'Registro procesado '
                    detail = |Salida del despacho { lv_response } se actualizo con exito (GCK)| ).
*              rv_return = save_exit( is_desp_exit = ls_guia ).

              rv_return = upd_stat_exit(
                 EXPORTING
                   is_romak     = ls_guia
                 CHANGING
                   et_resp_list = et_resp_list ).

            ELSE.

              ls_error_item = VALUE #(
                  code = 422
                  title = 'Registro no procesado '
                  detail = |Salida del despacho { lv_response } no se actualizo con exito (GCK)| ).

            ENDIF.

          WHEN '403'.

          WHEN '422'.
            ls_error_item = VALUE #(
                     code = lv_status_code
                     title = 'Registro no procesado'
                     detail = |No se pudo enviar el documento { lv_response }| ).
          WHEN '500'.
            ls_error_item = VALUE #(
                     code = lv_status_code
                     title = 'Error en el certificado SSL o se expiro'
                     detail = |Invalido del certificado SSL| ).
          WHEN OTHERS.
            ls_error_item = VALUE #(
                       code = lv_status_code
                       title = |Error desconocido { lv_status_code }|
                       detail = |detalle: { lv_reason } - { lv_response }| ).
        ENDCASE.

        APPEND ls_error_item TO et_resp_list.

*        ls_error_resp = VALUE #(
*            status = lv_status_code
*            reason = lv_reason
*            errors = lt_errors ).

        DATA(lv_json_error) = /ui2/cl_json=>serialize(
                           data        = lt_errors
                           pretty_name = /ui2/cl_json=>pretty_mode-low_case
                           compress    = abap_false ).

        cl_demo_output=>display( lv_response ).
        cl_demo_output=>display_json( json = lv_json_error ).

      CATCH cx_http_ext_exception INTO DATA(lx_error).
        WRITE: / 'Error al enviar el JSON:', lx_error->get_text( ).
        RETURN.
    ENDTRY.

    " Liberar recursos del cliente HTTP
    IF lo_client IS BOUND.
      lo_client->close( ).
    ENDIF.

*    rv_return = abap_true.
  ENDMETHOD.

  METHOD save_despacho.
    UPDATE zsd_tb_gck
       SET usr_desp = sy-uname
           env_desp = 'S'
           fec_desp = sy-datum
           hora_desp = sy-uzeit
     WHERE
*     tdocumento = 'GC' AND
           tknum = iv_tknum.

    commit_work( ).

    rv_return = abap_true.
  ENDMETHOD.

  METHOD commit_work.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

  METHOD save_exit.

    UPDATE zsd_tb_gck
         SET usr_exit = sy-uname
             fec_exit = is_desp_exit-fecha_salida
             hora_exit = is_desp_exit-hora_salida
       WHERE tknum = is_desp_exit-tknum AND
             ( tdocumento = 'GC' OR
               tdocumento = 'RXP' ).

    CHECK sy-subrc EQ 0.

    commit_work( ).

    rv_return = abap_true.

  ENDMETHOD.

  METHOD send_driver.
    CONSTANTS:
        lc_method TYPE string VALUE 'drivers'.

    DATA:
      ls_driver  TYPE zsd_st_driver_json,
      lt_drivers TYPE zsd_tt_driver_json,
      lv_url     TYPE string.

*    DATA(lo_romana) = NEW zcl_sd_romana_serv( iv_transp = abap_true ).
*
*    lo_romana->list_transportes(
*                     IMPORTING
*                       et_transp = lt_drivers ).

    ls_driver = VALUE zsd_st_driver_json(
        carrier_code = is_driver-carrier_code
        identity_number = |{ is_driver-nacionalidad }{ is_driver-cedula }|
        first_name = is_driver-nombre
        last_name = is_driver-apellido
        phone = is_driver-telefono
        email = is_driver-email ).

    ls_driver-status = COND zsd_status(
        WHEN is_driver-status EQ 1
        THEN |true|
        ELSE |false| ).

    APPEND ls_driver TO lt_drivers.

    TRY.
        lv_json = /ui2/cl_json=>serialize(
                 data        = lt_drivers
                 pretty_name = /ui2/cl_json=>pretty_mode-low_case  " Opcional
                 compress    = abap_false ).

        IF mv_display EQ abap_true.
          cl_demo_output=>display( lv_json ).
        ENDIF.

        lv_url = |{ ms_amb-url }/{ lc_method }|.

* crear el cliente http
        CALL METHOD cl_http_client=>create_by_url
          EXPORTING
            url                = lv_url
          IMPORTING
            client             = lo_client
          EXCEPTIONS
            argument_not_found = 1
            plugin_not_active  = 2
            internal_error     = 3
            OTHERS             = 4.

        IF sy-subrc <> 0 OR lo_client IS INITIAL.
          WRITE: 'Error al crear el cliente HTTP'.
          MESSAGE 'Error creando el cliente HTTP' TYPE 'E'.
          RAISE EXCEPTION TYPE cx_sy_no_handler.
*        EXPORTING
*          textid = cx_sy_no_handler=>textid.
          RETURN.
        ENDIF.

        " Establecer cabeceras obligatorias
        lo_client->request->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).

        lo_client->request->set_header_field(
            name  = 'Accept'
            value = 'application/json' ).

        lo_client->request->set_header_field(
            name  = 'x-api-key'
            value = CONV string( ms_amb-api_key ) ).

        lo_client->request->set_header_field(
            name  = 'Authorization'
            value = |Bearer { ms_amb-api_key }| ).

        lo_client->request->set_method( 'POST' ).

        lo_client->request->set_cdata( lv_json ).

        lo_client->send( ).

        IF sy-subrc <> 0.
          WRITE: 'Error al enviar la solicitud HTTP'.
          MESSAGE 'Error al enviar la solicitud HTTP' TYPE 'E'.
        ENDIF.

*        lo_client->receive( ).
        lo_client->receive(
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state         = 2
            http_processing_failed     = 3
            OTHERS                     = 4 ).

        " Establecer cabeceras obligatorias
        lo_client->response->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).
        "obtener el código de estado y la respuesta
        lo_client->response->get_status(
          IMPORTING
            code   = lv_status_code
            reason = lv_reason ).

        IF lv_status_code EQ '500'.
*          mv_men_1 = 'Certificado ha expirado'.
*          mv_men_2 = 'Por favor comunicarse con TI'.
          WRITE: |Error: { lv_status_code } Mensaje: { lv_reason }|.
*          'Error en el Certificado ó Certificado expirado'.
          MESSAGE |Error: { lv_status_code } Mensaje: { lv_reason }| TYPE 'I'.
          RETURN.
        ELSE.
*          mv_men_1 = 'Error al recibir respuesta del HTTP'.
*          CLEAR mv_men_2.
        ENDIF.

*        CHECK lv_status_code EQ '200'.

        lv_response = lo_client->response->get_cdata( ).

        IF mv_display EQ abap_true.
          cl_demo_output=>display( lv_response ).
        ENDIF.

      CATCH cx_http_ext_exception INTO DATA(lx_error).
        WRITE: / 'Error al enviar el JSON:', lx_error->get_text( ).
        RETURN.
    ENDTRY.

    " Liberar recursos del cliente HTTP
    IF lo_client IS BOUND.
      lo_client->close( ).
    ENDIF.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD upd_stat_exit.

    DATA(ls_trans) = VALUE zsd_st_stage(
          tknum = is_romak-tknum
          sttrg = '6'
          date_stage = is_romak-fecha_salida
          time_stage = is_romak-hora_salida ).

    IF zcl_sd_stat_transp=>update_stage( is_transp = ls_trans ) EQ abap_true.

*    UPDATE vttk
*     SET sttbg = 'X'
*         datbg = is_romak-fecha_salida
*         uatbg = is_romak-hora_salida
*   WHERE tknum = is_romak-tknum.
*
*    IF sy-subrc EQ 0.
      lv_status_code = 200.
      lv_reason = 'Actualizado'.

      ls_error_item = VALUE #(
            code = |OK-{ lv_status_code }|
            title = |Datos actualizados|
            detail = |Se actualizo el Status de salida del transporte: { is_romak-tknum }| ).
      rv_return = abap_true.
    ELSE.
      lv_status_code = 422.
      lv_reason = 'No guardado'.

      ls_error_item = VALUE #(
            code = |E-{ lv_status_code }|
            title = |Datos No actualizados|
            detail = |No se guardo el statusde salida del transporte: { is_romak-tknum }| ).
*      RETURN.
    ENDIF.
*
    APPEND ls_error_item TO et_resp_list.
*
*    commit_work( ).

  ENDMETHOD.

  METHOD update_stage.
    CONSTANTS:
      lc_method TYPE string VALUE 'trips/status-date'.

    TYPES:
      BEGIN OF st_travel,
        tipo_documento   TYPE ztdocumento,
        numero_documento TYPE znrodocumento,
        fecha_hora       TYPE zsd_date,
        estatus          TYPE c1,
      END OF st_travel.

    DATA:
*      lt_drivers TYPE zsd_tt_driver_json,
      lv_url    TYPE string,
      ls_travel TYPE st_travel,
      lv_time   TYPE  tims.

    ls_travel = VALUE #( tipo_documento = is_stage-tdocumento
                         numero_documento = is_stage-tknum
                         estatus = is_stage-sttrg ).

*    SELECT SINGLE tknum, fecha_salida, hora_salida
*          FROM zsd_tb_romanak
*          INTO @DATA(ls_guia)
*         WHERE tknum EQ @is_transp-tknum.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        input  = is_stage-tknum
      IMPORTING
        output = ls_travel-numero_documento.

*    WRITE sy-uzeit TO lv_time ENVIRONMENT TIME FORMAT.

    ls_travel-fecha_hora = |{ is_stage-date_stage+0(4) }-{ is_stage-date_stage+4(2) }-{ is_stage-date_stage+6(2) }|.
    ls_travel-fecha_hora = |{ ls_travel-fecha_hora } { is_stage-time_stage+0(2) }:{ is_stage-time_stage+2(2) }:{ is_stage-time_stage+4(2) }|.

    TRY.
        lv_json = /ui2/cl_json=>serialize(
                 data        = ls_travel
                 pretty_name = /ui2/cl_json=>pretty_mode-low_case
                 compress    = abap_false ).

        cl_demo_output=>display( lv_json ).

*        lv_url = |{ mc_url }/{ lc_method }|.
        lv_url = |{ ms_amb-url }/{ lc_method }|.

* crear el cliente http
        CALL METHOD cl_http_client=>create_by_url
          EXPORTING
            url                = lv_url
          IMPORTING
            client             = lo_client
          EXCEPTIONS
            argument_not_found = 1
            plugin_not_active  = 2
            internal_error     = 3
            OTHERS             = 4.

        IF sy-subrc <> 0 OR lo_client IS INITIAL.
          WRITE: 'Error al crear el cliente HTTP'.
          MESSAGE 'Error creando el cliente HTTP' TYPE 'E'.
          RAISE EXCEPTION TYPE cx_sy_no_handler.
*        EXPORTING
*          textid = cx_sy_no_handler=>textid.
          RETURN.
        ENDIF.

        " Establecer cabeceras obligatorias
        lo_client->request->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).

        lo_client->request->set_header_field(
            name  = 'Accept'
            value = 'application/json' ).

        lo_client->request->set_header_field(
            name  = 'x-api-key'
            value = CONV string( ms_amb-api_key ) ).

        lo_client->request->set_header_field(
            name  = 'Authorization'
            value = |Bearer { ms_amb-api_key }| ).

        lo_client->request->set_method( 'POST' ).

        lo_client->request->set_cdata( lv_json ).

        lo_client->send( ).

        IF sy-subrc <> 0.
          WRITE: 'Error al enviar la solicitud HTTP'.
          MESSAGE 'Error al enviar la solicitud HTTP' TYPE 'E'.
        ENDIF.

        lo_client->receive(
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state         = 2
            http_processing_failed     = 3
            OTHERS                     = 4 ).

        "obtener el código de estado y la respuesta
        lo_client->response->get_status(
          IMPORTING
            code   = lv_status_code
            reason = lv_reason ).

        lo_client->response->set_header_field(
            name  = 'Content-Type'
            value = 'application/json;charset=utf-8' ).

        lv_response = lo_client->response->get_cdata( ).

*        cl_demo_output=>display( lv_response ).

        CASE lv_status_code.
          WHEN '200' OR '201'.
            ls_error_item = VALUE #(
                   code = lv_status_code
                   title = 'Registro procesado '
                   detail = |El status del despacho { lv_response } se realizo con éxito (Innovo)| ).

            DATA(ls_guia) = VALUE ty_stat_exit( tknum = is_stage-tknum
                                                fecha_salida = is_stage-date_stage
                                                hora_salida = is_stage-time_stage ).

            IF save_exit( is_desp_exit = ls_guia ) EQ abap_true.

              APPEND ls_error_item TO et_resp_list.

              ls_error_item = VALUE #(
                    code = lv_status_code
                    title = 'Registro procesado '
                    detail = |el despacho { lv_response } se actualizo con exito (GCK)| ).
*              rv_return = save_exit( is_desp_exit = ls_guia ).

*              rv_return = upd_stat_exit(
*                 EXPORTING
*                   is_romak     = ls_guia
*                 CHANGING
*                   et_resp_list = et_resp_list ).

            ELSE.

              ls_error_item = VALUE #(
                  code = 422
                  title = 'Registro no procesado '
                  detail = |Salida del despacho { lv_response } no se actualizo con exito (GCK)| ).

            ENDIF.

          WHEN '403'.

          WHEN '422'.
            ls_error_item = VALUE #(
                     code = lv_status_code
                     title = 'Registro no procesado'
                     detail = |No se pudo enviar el documento { lv_response }| ).
          WHEN '500'.
            ls_error_item = VALUE #(
                     code = lv_status_code
                     title = 'Error en el certificado SSL o se expiro'
                     detail = |Invalido del certificado SSL| ).
          WHEN OTHERS.
            ls_error_item = VALUE #(
                       code = lv_status_code
                       title = |Error desconocido { lv_status_code }|
                       detail = |detalle: { lv_reason } - { lv_response }| ).
        ENDCASE.

        APPEND ls_error_item TO et_resp_list.

*        ls_error_resp = VALUE #(
*            status = lv_status_code
*            reason = lv_reason
*            errors = lt_errors ).

        DATA(lv_json_error) = /ui2/cl_json=>serialize(
                           data        = lt_errors
                           pretty_name = /ui2/cl_json=>pretty_mode-low_case
                           compress    = abap_false ).

        cl_demo_output=>display( lv_response ).
        cl_demo_output=>display_json( json = lv_json_error ).

      CATCH cx_http_ext_exception INTO DATA(lx_error).
        WRITE: / 'Error al enviar el JSON:', lx_error->get_text( ).
        RETURN.
    ENDTRY.

    " Liberar recursos del cliente HTTP
    IF lo_client IS BOUND.
      lo_client->close( ).
    ENDIF.

    CHECK lv_status_code EQ '200' OR lv_status_code EQ '201'.

    rv_return = abap_true.

  ENDMETHOD.

ENDCLASS.
