CLASS lcl_doc_fd DEFINITION.

  PUBLIC SECTION.

    CONSTANTS: gc_sistema     TYPE string VALUE 'QR3',
               gc_dest_dist   TYPE string VALUE 'recepcion_digital_crp@corimon.com',
               gc_status_e(1) TYPE c VALUE 'E',
               gc_guia(2)     TYPE c VALUE 'GC'.

    DATA mv_view TYPE abap_bool READ-ONLY.

    TYPES:

      tyr_tknum TYPE RANGE OF vttk-tknum,

      BEGIN OF ty_guia,
        tplst  TYPE tplst,
        tknum  TYPE tknum,
        dig_sl TYPE abap_bool,
*        proccess TYPE char3,
      END OF ty_guia,

      tt_guia TYPE ty_guia,

      BEGIN OF ty_json,
        id   TYPE i,
        json TYPE string,
      END OF ty_json,

      tt_json    TYPE STANDARD TABLE OF ty_json,
      ty_gc_head TYPE STANDARD TABLE OF zv_cds_sd_gc,
      ty_gc_item TYPE STANDARD TABLE OF zv_cds_gcp,

      BEGIN OF ty_tothead,
        paletas   TYPE i,
        palconsig TYPE i,
        kilos     TYPE i,
      END OF ty_tothead,

      BEGIN OF ty_totitem,
        totkcarga  TYPE dec8_2,
        totgalones TYPE dec8_2,
        totbultos  TYPE dec8_2,
      END OF ty_totitem,

      tt_destino TYPE SORTED TABLE OF zsd_st_oe
                        WITH UNIQUE KEY vbeln,

      BEGIN OF ty_ambiente,
        sysid   TYPE sy-sysid,
        url     TYPE zurl,
        api_key TYPE string,
      END OF ty_ambiente.

    DATA:
      ms_guia     TYPE tt_guia READ-ONLY,
      mv_json     TYPE string READ-ONLY,
      mv_json_fac TYPE string READ-ONLY,
      mv_json_oe  TYPE string READ-ONLY,
      mv_json_con TYPE string READ-ONLY,
      mv_proccess TYPE char3 READ-ONLY,
*      ms_json TYPE ty_js
*      ms_amb      TYPE ty_ambiente READ-ONLY,
      ms_service  TYPE zsd_st_serv_url READ-ONLY,
      ms_dat_gc   TYPE zsd_st_datos_gc.

    CLASS-DATA:
      lt_head     TYPE STANDARD TABLE OF zv_cds_sd_gc,
      lt_items    TYPE STANDARD TABLE OF zv_cds_gcp,
      lt_gc_head  TYPE STANDARD TABLE OF zv_cds_sd_gc,
      lt_gc_items TYPE STANDARD TABLE OF zv_cds_gcp,
      lt_gck      TYPE STANDARD TABLE OF zsd_tb_gck,
      lt_gcp      TYPE STANDARD TABLE OF zsd_tb_gcp,
      mt_json     TYPE STANDARD TABLE OF ty_json,
      mt_json_fac TYPE STANDARD TABLE OF ty_json,
      mt_json_oe  TYPE STANDARD TABLE OF ty_json.

    CLASS-DATA:
      lt_head_rxp   TYPE STANDARD TABLE OF zv_sd_gd_rxp,
      lt_gc_headrxp TYPE STANDARD TABLE OF zv_sd_gd_rxp.

    METHODS:
      constructor
        IMPORTING
          is_guia    TYPE ty_guia
          iv_orden   TYPE char3
          is_dat_gc  TYPE zsd_st_datos_gc OPTIONAL
          iv_mostrar TYPE abap_bool OPTIONAL
        RAISING
          cx_abap_invalid_value,

      init
        IMPORTING
          is_guia     TYPE ty_guia
          iv_proccess TYPE char3
          iv_mostrar  TYPE abap_bool OPTIONAL
        RAISING
          cx_abap_invalid_value,

      init_rxp
        IMPORTING
          is_guia     TYPE ty_guia
          iv_proccess TYPE char3
          iv_mostrar  TYPE abap_bool OPTIONAL
        RAISING
          cx_abap_invalid_value.

  PROTECTED SECTION.

  PRIVATE SECTION.
    TYPES:BEGIN OF ty_range,
            sign     TYPE /bcv/fnd_sign_range,
            option   TYPE /bcv/fnd_option,
            low(10)  TYPE c,
            high(10) TYPE c,
          END OF ty_range,

          tt_range       TYPE STANDARD TABLE OF ty_range,
          ty_oe_item     TYPE STANDARD TABLE OF zview_entp_oe,
          ty_transp_head TYPE STANDARD TABLE OF zview_entrega_oe.

    DATA: lv_json    TYPE string,
          lv_jsonfac TYPE string,
          lv_jsonoe  TYPE string,
          lt_lfart   TYPE tt_range,
          lv_error   TYPE string.

    DATA ls_dat_cg TYPE zsd_st_datos_gc.

    METHODS:
      get_gc
        IMPORTING
          iv_orden       TYPE char3 OPTIONAL
        EXPORTING
          ev_json        TYPE string
        RETURNING
          VALUE(rt_json) TYPE ty_json,

      create_json_gc
        IMPORTING
          iv_document      TYPE c
          !it_head         TYPE ty_gc_head
          !it_items        TYPE ty_gc_item
        EXPORTING
          !et_json         TYPE tt_json
          ev_json          TYPE string
        CHANGING
          et_destino       TYPE tt_destino  "zsd_tt_oe
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      get_banner IMPORTING iv_tpls          TYPE tplst
                           iv_fecha         TYPE sy-datum
                 RETURNING VALUE(rv_banner) TYPE zbanners,

      create_json_fac
        IMPORTING !it_fac TYPE ty_gc_item
        EXPORTING ev_json TYPE string,

*      create_json_oe
*        IMPORTING !it_fac TYPE ty_gc_item
*        EXPORTING ev_json TYPE string.
*
**        IMPORTING is_guia TYPE ty_guia
*        .

      set_char_esp IMPORTING iv_string TYPE c
                   EXPORTING ev_string TYPE c,

      create_json_oe IMPORTING iv_document      TYPE c
*                               iv_fecdoc        TYPE sy-datum
                               !it_head         TYPE ty_transp_head
                               !it_items        TYPE ty_oe_item
                               it_destino       TYPE tt_destino  "zsd_tt_oe
                               it_items_gc      TYPE ty_gc_item
                     EXPORTING ev_json          TYPE string
                     RETURNING VALUE(rv_return) TYPE abap_bool,

      create_json_consolidado
        IMPORTING
                  iv_json_gc     TYPE string
                  iv_json_fac    TYPE string
                  iv_json_oe     TYPE string
        RETURNING VALUE(rv_json) TYPE string,

*      get_url
*        CHANGING it_table TYPE ty_gc_item,

      proccess_rxp.
*        IMPORTING
*          is_dat_gc TYPE zsd_st_datos_gc.

ENDCLASS.

CLASS lcl_doc_fd IMPLEMENTATION.

  METHOD constructor.
    me->mv_proccess = iv_orden.
    me->ms_dat_gc = is_dat_gc.

*    IF iv_orden EQ 'RXP'.
*      lt_lfart = VALUE #( ( option = 'EQ' sign = 'I' low = 'ZECN' ) ).
*
*    ELSE.
    lt_lfart = VALUE #(
        ( option = 'EQ' sign = 'I' low = 'LR' )
        ( option = 'EQ' sign = 'I' low = 'NL' )
        ( option = 'EQ' sign = 'I' low = 'ZECN' ) ).
*    ENDIF.

*    ms_guia = VALUE #( tplst = is_guia-tplst
*                       tknum = is_guia-tknum
*                       dig_sl = is_guia-dig_sl ).

    mv_view = iv_mostrar.

*    TRY.
        DATA(lo_serv_url) = NEW zcl_sd_serv_digital( ).

        ms_service = VALUE #( sysid = sy-sysid
                              bukrs = is_guia-tplst
                              servicio = 'INNOVO' ).

        lo_serv_url->init( is_service = ms_service ).

        DATA(lv_return) =  lo_serv_url->get_services(
           CHANGING
             es_service = ms_service ).

        IF lv_return EQ abap_false.

*          zcl_error_helper=>raise_with_audit_log(
*              iv_text    = |No hay servicio definido { ms_service-servicio }|
*              iv_context = zcl_runtime_info=>get_current_location( ) ).
        ENDIF.

        get_gc( mv_proccess ).
*      CATCH zcx_app_error INTO DATA(lo_err).
*        MESSAGE lo_err->get_text( ) TYPE 'E'.
*    ENDTRY.

  ENDMETHOD.

  METHOD init.
*    me->mv_orden = iv_orden.

*    IF iv_orden EQ 'RXP'.
*      lt_lfart = VALUE #( ( option = 'EQ' sign = 'I' low = 'ZECN' ) ).
*
*    ELSE.
*      lt_lfart = VALUE #(
*          ( option = 'EQ' sign = 'I' low = 'LR' )
*          ( option = 'EQ' sign = 'I' low = 'NL' )
*          ( option = 'EQ' sign = 'I' low = 'ZECN' ) ).
*    ENDIF.

    ms_guia = VALUE #( tplst = is_guia-tplst
                       tknum = is_guia-tknum
                       dig_sl = is_guia-dig_sl ).

    mv_view = iv_mostrar.

**    TRY.
*        DATA(lo_serv_url) = NEW zcl_sd_serv_digital( ).
*
*        ms_service = VALUE #( sysid = sy-sysid
*                              bukrs = ms_guia-tplst
*                              servicio = 'INNOVO' ).
*
*        lo_serv_url->init( is_service = ms_service ).
*
*        DATA(lv_return) =  lo_serv_url->get_services(
*           CHANGING
*             es_service = ms_service ).
*
*        IF lv_return EQ abap_false.
*          MESSAGE 'No hay servicio definido' TYPE 'I'.
*          RAISE EXCEPTION TYPE cx_abap_invalid_value.
*        ENDIF.
*
*        IF lv_return EQ abap_false.
*
*          DATA:
**                lt_stack  TYPE call_stack_internal, "abap_callstack,
*                lv_metodo TYPE string.
*
*          " Obtener la pila de llamadas
*          CALL METHOD cl_abap_get_call_stack=>get_call_stack
*            RECEIVING
*              stack = DATA(lt_stack).
**            RECEIVING
**              call_stack = lt_stack.
*
*          " El primer registro después de este método es el actual
*          READ TABLE lt_stack INDEX 1 INTO DATA(ls_stack).
*          IF sy-subrc = 0.
*            lv_metodo = ls_stack-program_info. " Nombre del método
*          ENDIF.
*
*          WRITE: / 'Método actual:', lv_metodo.
*          zcl_error_helper=>raise_with_audit_log(
*              iv_text    = |No hay servicio definido { ms_service-servicio }|
*              iv_context = |ZCL_SD_DOC_FC->constructor { ls_stack-program_info }| ).
*        ENDIF.

        get_gc( mv_proccess ).
**      CATCH zcx_app_error INTO DATA(lo_err).
**        MESSAGE lo_err->get_text( ) TYPE 'E'.
**    ENDTRY.

  ENDMETHOD.

  METHOD init_rxp.
*    me->mv_orden = iv_orden.

*    IF iv_orden EQ 'RXP'.
    lt_lfart = VALUE #( ( option = 'EQ' sign = 'I' low = 'ZECN' ) ).
*    ELSE.
*      lt_lfart = VALUE #(
*          ( option = 'EQ' sign = 'I' low = 'LR' )
*          ( option = 'EQ' sign = 'I' low = 'NL' )
*          ( option = 'EQ' sign = 'I' low = 'ZECN' ) ).
*    ENDIF.

    ms_guia = VALUE #( tplst = is_guia-tplst
                       tknum = is_guia-tknum
                       dig_sl = is_guia-dig_sl ).

    mv_view = iv_mostrar.

*    TRY.
*
*        DATA(lo_serv_url) = NEW zcl_sd_serv_digital( ).
*
*        ms_service = VALUE #( sysid = sy-sysid
*                              bukrs = ms_guia-tplst
*                              servicio = 'INNOVO' ).
*
*        lo_serv_url->init( is_service = ms_service ).
*
*        DATA(lv_return) =  lo_serv_url->get_services(
*           CHANGING
*             es_service = ms_service ).
*
*        IF lv_return EQ abap_false.
*          MESSAGE 'No hay servicio definido' TYPE 'I'.
*          RAISE EXCEPTION TYPE cx_abap_invalid_value.
*        ENDIF.
*
*        IF lv_return EQ abap_false.
*
*          DATA:
**                lt_stack  TYPE call_stack_internal, "abap_callstack,
*                lv_metodo TYPE string.
*
*          " Obtener la pila de llamadas
*          CALL METHOD cl_abap_get_call_stack=>get_call_stack
*            RECEIVING
*              stack = DATA(lt_stack).
**            RECEIVING
**              call_stack = lt_stack.
*
*          " El primer registro después de este método es el actual
*          READ TABLE lt_stack INDEX 1 INTO DATA(ls_stack).
*          IF sy-subrc = 0.
*            lv_metodo = ls_stack-program_info. " Nombre del método
*          ENDIF.
*
*          WRITE: / 'Método actual:', lv_metodo.
*          zcl_error_helper=>raise_with_audit_log(
*              iv_text    = |No hay servicio definido { ms_service-servicio }|
*              iv_context = |ZCL_SD_DOC_FC->constructor { ls_stack-program_info }| ).
*        ENDIF.

    proccess_rxp( ).
*    get_gc( mv_proccess ).
*      CATCH zcx_app_error INTO DATA(lo_err).
*    MESSAGE lo_err->get_text( ) TYPE 'E'.
*ENDTRY.

  ENDMETHOD.

  METHOD get_gc.
    DATA: lr_tknum  TYPE RANGE OF vttk-tknum,
          lv_return TYPE abap_bool.

    DATA lt_destino TYPE tt_destino. "  .zsd_tt_oe

*    DATA lt_vttk TYPE STANDARD TABLE OF zview_gc.

    TRY.
        DATA(lo_docdig) = NEW zcl_sd_doc_digital( ).
      CATCH cx_abap_invalid_value.
*              out->write( | Carrier { c_carrier_id } does not exist | ).
    ENDTRY.

    SELECT nrotransp, env_desp
      FROM zview_gc( p_tplst = @ms_guia-tplst )
*      INTO TABLE @lr_tknum-low
      INTO TABLE @DATA(lt_vttk)
*     INTO @DATA(ls_vttk)
     WHERE nrotransp_k EQ @ms_guia-tknum.

    IF sy-subrc NE 0.
      MESSAGE 'No hay datos' TYPE 'I'.
    ENDIF.

    CHECK lt_vttk[] IS NOT INITIAL.

    SORT lt_vttk BY nrotransp.
    DELETE ADJACENT DUPLICATES FROM lt_vttk COMPARING nrotransp.

    IF line_exists( lt_vttk[ env_desp = 'S' ] ).
      MESSAGE |Se envío el despacho { ms_guia-tknum } | TYPE 'I'.
*      EXIT.
    ENDIF.
*
*    READ TABLE lt_vttk WITH KEY env_desp = 'S' TRANSPORTING NO FIELDS.

    LOOP AT lt_vttk INTO DATA(ls_vttk).
      APPEND VALUE #( sign = 'I' option = 'EQ' low = ls_vttk-nrotransp )
       TO lr_tknum.
    ENDLOOP.

*    lr_tknum = VALUE #( (  sign = 'I' option = 'EQ' low = ms_guia-tknum ) ).

    IF lo_docdig->get_gc_enc(
      EXPORTING
        iv_tplst  = ms_guia-tplst
        it_tknum  = lr_tknum
        iv_proccess = mv_proccess
        is_dat_gc = ls_dat_cg
      IMPORTING
        et_table  = lt_head ) EQ abap_false.
      EXIT.
    ENDIF.

    IF lo_docdig->get_gc_items(
         EXPORTING
           it_tknum  = lr_tknum[]
           iv_proccess = iv_orden
         IMPORTING
           et_table  = lt_items[] ) EQ abap_false.

      IF lt_items[] IS INITIAL.
        EXIT.
      ENDIF.

    ENDIF.

    IF lo_docdig->get_destino(
      EXPORTING
        it_table = lt_items
      CHANGING
        et_table = lt_head ) EQ abap_false.
    ENDIF.

    CLEAR lt_destino.

    SORT lt_items BY nrodocumento.

* Crea Json Guía de Carga
    create_json_gc(
      EXPORTING
        iv_document = gc_guia
        it_head     = lt_head[] "lt_gc_head[]
        it_items    = lt_items[] "lt_gc_items[]
      IMPORTING
        ev_json     = ev_json
        et_json     = mt_json[]
      CHANGING
        et_destino  = lt_destino[]
      RECEIVING
        rv_return   = lv_return ).

* Crea el Json de Factura
    create_json_fac(
      EXPORTING
        it_fac  = lt_items[]
      IMPORTING
        ev_json = ev_json ).

    DATA: lt_oe_head  TYPE STANDARD TABLE OF zview_entrega_oe,
          lt_oe_items TYPE STANDARD TABLE OF zview_entp_oe,
          lt_head_oe  TYPE STANDARD TABLE OF zview_entrega_oe,
          lt_items_oe TYPE STANDARD TABLE OF zview_entp_oe.

* particionas las paginas de las ordenes de entrega
    IF iv_orden = 'GD'.
      DATA(lv_orden) = 'LR'.
    ELSE.
      lv_orden = 'OE'.
    ENDIF.

* Busca todos las ordene de Entregas asociadas al transporte
    IF lo_docdig->get_transp_oe(
     EXPORTING
       iv_tplst  = ms_guia-tplst
       it_tknum  = lr_tknum[]
       iv_orddev = lv_orden
     IMPORTING
       et_head  = lt_oe_head[]
       et_items = lt_oe_items[] ) EQ abap_false.

    ENDIF.

    IF lt_oe_head[] IS NOT INITIAL.

      IF lo_docdig->send_oe(
                EXPORTING
                  iv_document = lv_orden
                  it_head     = lt_oe_head[]
                  it_items    = lt_oe_items[]
                IMPORTING
                  et_head     = lt_head_oe[]
                  et_items    = lt_items_oe[] ) EQ abap_false.

      ENDIF.

      IF create_json_oe(
          EXPORTING
            iv_document = lv_orden "iv_orden
*          iv_fecdoc   = lv_fecpro
            it_head     = lt_head_oe[] "t_oe_head[]
            it_items    = lt_items_oe[] "t_oe_items[]
            it_destino  = lt_destino[]
            it_items_gc = lt_items[]
          IMPORTING
            ev_json     = lv_json ) EQ abap_false.

      ENDIF.
    ENDIF.

    mv_json_con = create_json_consolidado(
      EXPORTING
        iv_json_gc  = mv_json
        iv_json_fac = mv_json_fac
        iv_json_oe  = mv_json_oe ).

  ENDMETHOD.

  METHOD create_json_gc.

    DATA(lo_doc_digital) = NEW zcl_sd_doc_digital( ).

    DATA lt_json TYPE STANDARD TABLE OF ty_json.

    CLEAR lt_json.
    REFRESH lt_json.

    DATA: ls_tothead TYPE ty_tothead,
          ls_totitem TYPE ty_totitem.

*    CLEAR technical_message.

    DATA: lv_men_1    TYPE symsgv,
          lv_men_2    TYPE symsgv,
          lv_pag(2)   TYPE c,
          lv_hora     TYPE tims,
          lv_am_pm(2) TYPE c.

    DATA: ls_cab TYPE zsd_st_gd_json, " zsd_st_dd_json,
          ls_det TYPE zsd_st_desp_detalle, "zsd_st_dd_detalle.
          ls_url TYPE zsd_st_url.

    DATA: lv_json   TYPE string,
          ls_json   TYPE zsd_st_json_status,
          ti_report TYPE TABLE OF zsd_st_gd_json. "zsd_st_gc_json. " zsd_st_dd_json.

    DATA: it_inputparams TYPE tihttpnvp,
          ls_inputparams TYPE LINE OF tihttpnvp.

    DATA wa_duplica TYPE ty_gc_item.

    DATA ls_log TYPE zsd_tb_oe_log.

    wa_duplica[] = it_items[].

    DELETE ADJACENT DUPLICATES FROM wa_duplica COMPARING dircliente.

    DESCRIBE TABLE wa_duplica LINES DATA(lv_repartos).

    REFRESH: ti_report.

    LOOP AT it_head INTO DATA(ls_head)
      WHERE frkrl EQ abap_true.
      CLEAR ls_cab.

      SELECT SINGLE *
        FROM zsd_tb_gck
       WHERE tplst EQ @ls_head-tplst AND
             tknum EQ @ls_head-nrotrans
        INTO @DATA(ls_gck).

* Totales del Head
      ls_tothead = REDUCE ty_tothead( INIT tot TYPE ty_tothead
                                      FOR wa IN it_head
*                                          WHERE ( pag EQ ls_head-pag )
                                          NEXT tot-paletas = tot-paletas + wa-paleta
                                               tot-palconsig = tot-palconsig + wa-kulab ).

* Totales Items
      ls_totitem = REDUCE ty_totitem( INIT tot_i TYPE ty_totitem
                                        FOR wa_i IN it_items
*                                          WHERE ( pag EQ ls_head-pag )
                                            NEXT tot_i-totkcarga = tot_i-totkcarga + wa_i-kgcarga
                                                 tot_i-totgalones = tot_i-totgalones + wa_i-galones
                                                 tot_i-totbultos = tot_i-totbultos + wa_i-bultos ).

      IF iv_document = 'GD'.
        DATA(lv_document) = 'GC'.
      ELSE.
        lv_document = iv_document.
      ENDIF.

      ls_cab = VALUE zsd_st_gd_json(
         tdocumento     = iv_document
         femision       = ls_gck-erdat
         hemision       = sy-uzeit
         nrotransporte  = ls_head-nrotrans
         puesto         = ls_head-puesto
         conductor      = ls_head-conductor
         telefono       = ls_head-telefono
         estado         = ls_head-estado
         ciudad         = ls_head-ciudad
         pasevigila     = ls_head-pasevigilancia
         transporte     = ls_head-transp
         tipovehiculo   = ls_head-tipveh
         totalkilo      = ls_totitem-totkcarga
         totalgalones   = ls_totitem-totgalones
         hojaservic     = ls_head-nrohoja
         nroplaca       = ls_head-placa
         doccompra      = ls_head-acepservicio
         totalbulto     = ls_totitem-totbultos
         cantidadrepart = lv_repartos
         observaciones  = ls_head-observaciones
         ordevolucion   = ls_head-orddev
         ordequipo      = ls_head-ordequi
         paletaentreg   = ls_tothead-paletas
         nroprecinto    = ls_head-precintos
         pesoromana     = ls_head-pesoromana
         nc             = ls_head-notcred
         superdespacho  = ls_head-supervisor
         preparador     = ls_head-preparador
         paletaconsig   = ls_tothead-palconsig
         despachador    = ls_head-despachador
         riftransporte  = ls_head-tdlnr
         ciconductor    = ls_head-ciconductor ).

      ls_cab-dias_ruta = ls_head-gesztd / 240000.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = ls_head-nrotrans
        IMPORTING
          output = ls_cab-nrotransporte.

      CONDENSE: ls_cab-nrotransporte NO-GAPS,
                ls_cab-totalkilo NO-GAPS,
                ls_cab-totalgalones NO-GAPS,
                ls_cab-paletaentreg NO-GAPS,
                ls_cab-paletaconsig NO-GAPS.

      IF sy-sysid NE gc_sistema.
        DATA(lt_correo) = VALUE zsd_tt_det_correo(
               ( correo = ls_head-correo )
               ( correo = ls_head-correotransp )
               ( correo = gc_dest_dist ) ).

      ELSE.
        CLEAR: ls_cab-correo, lt_correo.
        REFRESH lt_correo.

        lt_correo = VALUE zsd_tt_det_correo(
               ( correo = 'carlos_falcon@corimon.com' )
               ( correo = 'pedro_marquez@corimon.com' )
               ( correo = 'jonathan_gonzalez@corimon.com' )
               ( correo = 'angee_mendoza@corimon.com' ) ).

      ENDIF.

      MOVE lt_correo[] TO ls_cab-correo[].

      ls_cab-banners = get_banner( iv_tpls  = ls_head-tplst
                                   iv_fecha = ls_gck-erdat ).

      WRITE sy-datum TO ls_cab-femision DD/MM/YYYY.

      REPLACE ALL OCCURRENCES OF '.' IN ls_cab-femision WITH '/'.
      REPLACE ALL OCCURRENCES OF '"' IN ls_cab-ciudad WITH ' '.

      lv_hora = ls_gck-erzet.

      CALL FUNCTION 'HRVE_CONVERT_TIME'
        EXPORTING
          type_time       = 'A'
          input_time      = lv_hora
          input_am_pm     = 'AM'
        IMPORTING
          output_time     = lv_hora
          output_am_pm    = lv_am_pm
        EXCEPTIONS
          parameter_error = 1.

      WRITE lv_hora TO ls_cab-hemision ENVIRONMENT TIME FORMAT .

      IF lv_am_pm EQ 'AM'.
        CONCATENATE ls_cab-hemision 'a.m.' INTO ls_cab-hemision SEPARATED BY  ' '.
      ELSE.
        CONCATENATE ls_cab-hemision 'p.m.' INTO ls_cab-hemision SEPARATED BY  ' '.
      ENDIF.

      LOOP AT it_items INTO DATA(ls_item).
*        WHERE pag EQ ls_head-pag.
        CLEAR ls_det.

        IF ls_item-lfart IN lt_lfart.
          APPEND VALUE #(
            vbeln      = ls_item-nrodocumento
            rifdestino = ls_item-rifdestino
            nomdestino = ls_item-nomcliente )
        TO et_destino.
        ENDIF.

        ls_det = VALUE zsd_st_desp_detalle(
                    cliente      = ls_item-nomcliente
                    nrodocumento = ls_item-nrodocumento
                    bultos       = ls_item-bultos
                    ciudad       = ls_item-city1
                    dir_gps      = ls_item-ablad ).

        IF ls_item-lfart NOT IN lt_lfart.
          SELECT SINGLE url
            FROM zsd_tb_json_stat
            INTO @DATA(lv_url)
           WHERE vbeln EQ @ls_det-nrodocumento.

          ls_url = VALUE zsd_st_url( url = lv_url ).

          APPEND ls_url TO ls_det-url[].
        ELSE.
          SELECT url
            FROM zsd_likp_oe AS oe
            INNER JOIN zsd_tb_json_stat AS js
                ON oe~tplst EQ js~bukrs AND
                   oe~tdocumento EQ js~tdocumento AND
                   oe~vbeln_oe EQ js~vbeln
            INTO TABLE @DATA(lt_url)
            WHERE oe~vbeln_oe EQ @ls_det-nrodocumento.

          LOOP AT lt_url INTO DATA(ws_url).
            ls_url = VALUE zsd_st_url( url = ws_url ).

            APPEND ls_url TO ls_det-url[].
          ENDLOOP.

          IF ls_item-lfart EQ 'NL'.
            ls_det-distribuidor = 'SI'.
          ELSE.
            ls_det-distribuidor = 'NO'.
          ENDIF.

        ENDIF.

        REPLACE ALL OCCURRENCES OF '"' IN ls_det-ciudad WITH ' '.

        APPEND ls_det TO ls_cab-detalles[].
      ENDLOOP.

      APPEND ls_cab TO ti_report.

      CLEAR lv_json.

    ENDLOOP.

    zcl_json_utility=>convert_itab_to_json(
      EXPORTING
        im_t_table = ti_report
        im_v_case  = zcl_json_utility=>co_ftype_lowercase
      RECEIVING
        rt_v_json  = lv_json ).

    mv_json = lv_json.
    ev_json = lv_json.

    et_json[] = lt_json[].
    mt_json[] = lt_json[].

  ENDMETHOD.

  METHOD get_banner.
    DATA: lv_banner TYPE zbanners VALUE 'bannerenero'.

    SELECT SINGLE banners
      FROM zsd_tb_banners
      INTO @lv_banner
     WHERE bukrs = @iv_tpls
       AND fecinicio LE @iv_fecha
       AND fecfinal  GE @iv_fecha.

    IF sy-subrc = 0.
      CONCATENATE lv_banner '.jpg' INTO lv_banner.
    ENDIF.

    TRANSLATE lv_banner TO LOWER CASE.

    rv_banner = lv_banner.
  ENDMETHOD.

  METHOD create_json_fac.
    CONSTANTS lc_enviado TYPE na_vsztp VALUE '1'.

    TRY.
        DATA(lo_facdig) = NEW zcl_enviarfactdigital( ).
      CATCH cx_abap_invalid_value.
*              out->write( | Carrier { c_carrier_id } does not exist | ).
    ENDTRY.

    lv_jsonfac = '['.

    DATA(lv_rec) = REDUCE i( INIT x = 0 FOR wa IN it_fac
                                    WHERE ( lfart NOT IN lt_lfart )
                                    NEXT x = x + 1 ).

    LOOP AT it_fac INTO DATA(ls_fac)
        WHERE lfart NOT IN lt_lfart.
      CLEAR lv_error.

      lv_rec = lv_rec - 1.

      lo_facdig->enviar_doc_facncnd(
      EXPORTING
        sociedad    = ms_guia-tplst    " Sociedad
        factura     = ls_fac-nrodocumento    " Número de documento comercial
        enviado     = lc_enviado    " Modalidad de envío
      IMPORTING
        error       = lv_error
      RECEIVING
        result_json = lv_json ).

      IF lv_error IS INITIAL.
        lv_jsonfac = |{ lv_jsonfac } { lv_json }|.
      ENDIF.

      IF lv_rec NE 0.
        lv_jsonfac = |{ lv_jsonfac },|.
      ENDIF.
    ENDLOOP.

    lv_jsonfac = |{ lv_jsonfac } ]|.

    ev_json = lv_jsonfac.
    mv_json_fac = lv_jsonfac.

  ENDMETHOD.

  METHOD create_json_oe.

    CONSTANTS: lc_asunto TYPE so_obj_des VALUE 'Error de comunicación con servicio SL'.

    TYPES:
      BEGIN OF ty_totales,
        totkilos   TYPE zpesototal,
        totgalones TYPE zgalones,
        totgal     TYPE ztotgal,
        paletas    TYPE zpaletas,
        totbultos  TYPE zbulto,
        palconsig  TYPE zpaletas,
        totimporte TYPE zimptotal,
        totimport  TYPE zimptotal,
      END OF ty_totales.

    DATA: ls_user    TYPE zv_user_function,
          ls_totales TYPE ty_totales.

    DATA(lo_docdig) = NEW zcl_sd_doc_digital( ).

*    CLEAR: technical_message, ls_message.

    DATA: ls_cab TYPE zsd_st_json_desp,
          ls_det TYPE zsd_det_desp. "zsd_deta.

    DATA: lv_docvir(10) TYPE c,
          lv_error      TYPE abap_bool,
          lv_json       TYPE string,
          lv_pag(2)     TYPE c,
          lv_hora       TYPE  tims,
          lv_fecpro     TYPE datum,
          lv_banners    TYPE zbanners,
          ti_report     TYPE TABLE OF zsd_st_json_desp.

    DATA: lv_men_1 TYPE symsgv,
          lv_men_2 TYPE symsgv.

    DATA: lv_totkilos   TYPE zpesototal,
          lv_totgalones TYPE zgalones,

          lv_paletas    TYPE zpaletas,
          lv_totbultos  TYPE zbulto,
          lv_palconsig  TYPE zpaletas,
          lv_totimporte TYPE zimptotal,
          lv_totimport  TYPE zimptotal.

    DATA: lv_totgal TYPE ztotgal.

    DATA: lv_status(1) TYPE c VALUE 'S'.

    DATA ls_log TYPE zsd_tb_oe_log.

    REFRESH: ti_report.

    lv_error = abap_false.

    CLEAR ls_totales.

    lv_jsonoe = '['.
*    BREAK-POINT.
    DATA(lv_rec) = lines( it_head ).

    LOOP AT it_head INTO DATA(ls_head).
      lv_rec = lv_rec - 1.

      CLEAR lv_docvir.

      lv_totkilos = 0.
      lv_totimporte = 0.
      lv_totbultos = 0.
      lv_totgalones = 0.
      lv_totgal = 0.

      SELECT SINGLE *
        FROM zsd_likp_oe
       WHERE tplst EQ @ls_head-orgvta AND
             vbeln EQ @ls_head-nroentrega AND
             pag EQ @ls_head-pag
        INTO @DATA(ls_docdig).

      IF ls_docdig-estado EQ lv_status. "'S'.


        lv_docvir = ls_docdig-vbeln_oe.

        CLEAR ls_cab.

        IF iv_document EQ 'LR'.
          DATA(lv_tipdoc) = 'OR'.
        ELSE.
          lv_tipdoc = iv_document.
        ENDIF.

        ls_cab = VALUE zsd_st_json_desp( tdocumento = lv_tipdoc
                                    ndocumento     = lv_docvir
                                    femision       = ls_docdig-femision
                                    hemision       = ls_docdig-hemision
                                    razonsocial    = ls_head-razonsocial
                                    telefono       = ls_head-telefono
                                    codcliente     = ls_head-rif
                                    rif            = ls_head-rif
                                    correo         = ls_head-correo
                                    nropedido      = ls_head-nropedido
                                    transporte     = ls_head-transporte
                                    plvehiculo     = ls_head-nroplaca
                                    direceptor     = ls_head-direceptor
                                    observaciones  = ls_head-observaciones ).

        IF ls_head-lfart NE 'NL'.

          DATA(dest_raw) = it_destino[ vbeln = ls_docdig-vbeln_oe ].
          DATA(client_raw) = it_items_gc[ nrodocumento = ls_docdig-vbeln_oe ].

          ls_cab-razonsocial = dest_raw-nomdestino.
          ls_cab-razonsocial = client_raw-nomcliente.

          ls_cab-codcliente = dest_raw-rifdestino.
          ls_cab-rif = dest_raw-rifdestino.
        ENDIF.

        WRITE ls_head-pag TO lv_pag.

        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING
            input  = lv_pag   " C field
          IMPORTING
            output = lv_pag.   " Internal display of INPUT, any category

        CONCATENATE ls_head-nroentrega '-' lv_pag
               INTO ls_cab-gdespacho.

        CONCATENATE ls_head-pais '-' ls_head-ciudad
        INTO ls_cab-paisciudad
        SEPARATED BY space.

        WRITE ls_docdig-femision TO ls_cab-femision DD/MM/YYYY.

        REPLACE ALL OCCURRENCES OF '.' IN ls_cab-femision WITH '/'.

        lv_hora = ls_cab-hemision.

        CALL FUNCTION 'HRVE_CONVERT_TIME'
          EXPORTING
            type_time       = 'A'
            input_time      = lv_hora
            input_am_pm     = 'AM'
          IMPORTING
            output_time     = lv_hora
          EXCEPTIONS
            parameter_error = 1.

        WRITE lv_hora TO ls_cab-hemision ENVIRONMENT TIME FORMAT .

        IF ls_docdig-hemision(2) > 12.
          CONCATENATE ls_cab-hemision 'p.m.' INTO ls_cab-hemision SEPARATED BY  ' '.
        ELSE.
          CONCATENATE ls_cab-hemision 'a.m.' INTO ls_cab-hemision SEPARATED BY  ' '.
        ENDIF.

        CONCATENATE ls_head-dir1 ls_head-dir2 ls_head-dir3
               INTO ls_cab-dfiscal SEPARATED BY space.

        IF ls_cab-direceptor IS INITIAL.
          ls_cab-direceptor = ls_cab-dfiscal.
        ENDIF.

        TRANSLATE ls_cab-paisciudad TO UPPER CASE.

        CONCATENATE ls_head-correodestino ',' "'/'
                    gc_dest_dist
                 INTO ls_cab-correo.

        SELECT SINGLE *
          FROM zv_user_function( p_bname = @sy-uname )
          INTO @ls_user.

        IF sy-subrc EQ 0.
          CONCATENATE ls_cab-correo '/'
                      ls_user-smtp_addr
                   INTO ls_cab-correo.
        ENDIF.

        IF sy-sysid EQ gc_sistema.
          CLEAR ls_cab-correo.

          CONCATENATE 'pedro_marquez@corimon.com' ','
                      'carlos_falcon@corimon.com' ','
                      'jonathan_gonzalez@corimon.com'
                 INTO ls_cab-correo.
        ENDIF.

        set_char_esp(
          EXPORTING
            iv_string = ls_cab-codcliente
          IMPORTING
            ev_string = ls_cab-codcliente ).

        set_char_esp(
          EXPORTING
            iv_string = ls_cab-plvehiculo
          IMPORTING
            ev_string = ls_cab-plvehiculo ).

        set_char_esp(
          EXPORTING
            iv_string = ls_cab-direceptor
          IMPORTING
            ev_string = ls_cab-direceptor ).

        ls_cab-banners = get_banner( iv_tpls  = ls_head-orgvta
                                     iv_fecha = ls_docdig-erdat ).

        LOOP AT it_items INTO DATA(ls_item)
          WHERE nroentrega EQ ls_head-nroentrega AND
                pag EQ ls_head-pag.

          CLEAR ls_det.

          ls_det = VALUE zsd_det_desp( codmaterial    = ls_item-matnr
                                       nrolote        = ls_item-nrolote
                                       prodescripcion = ls_item-desmaterial
                                       unimedida      = ls_item-unidmed
                                       preunitario    = ls_item-preciounitario
                                       tipo_item      = |PRO| ).
          .
          ls_det-cantidad = round( val = ( ls_item-cantidad ) dec = 0  ).
          ls_det-galones  = round( val = ( ls_item-galones ) dec = 2  ).

          ls_totales-totkilos = ls_totales-totkilos + ls_item-kilos.
          ls_totales-totgalones = ls_totales-totgalones + ls_item-galones.
          ls_totales-totgal = ls_totales-totgal + ls_item-galones.
          ls_totales-totbultos = ls_totales-totbultos + ls_item-cantidad.
          ls_totales-totimporte = ls_totales-totimporte + ( ls_item-galones * ls_item-preciounitario ).
          ls_totales-totimport = ls_totales-totimport + ls_item-netwr.

          TRANSLATE ls_det-unimedida TO UPPER CASE.

          WRITE: ls_det-cantidad TO ls_det-cantidad NO-GROUPING DECIMALS 2 NO-GAP,
                 ls_det-preunitario TO ls_det-preunitario NO-GROUPING DECIMALS 2 NO-GAP,
                 ls_det-galones TO ls_det-galones NO-GROUPING DECIMALS 2 NO-GAP.

          CONDENSE: ls_det-cantidad NO-GAPS,
                    ls_det-preunitario NO-GAPS,
                    ls_det-galones NO-GAPS.

          APPEND ls_det TO ls_cab-detalles[].

        ENDLOOP.

        ls_totales-totgalones = round( val = ( ls_totales-totgal ) dec = 2  ).

        ls_cab-oepesotot = ls_totales-totkilos.
        ls_cab-oeimptot  = ls_totales-totimporte.
        ls_cab-oecantot  = ls_totales-totbultos.
        ls_cab-galones   = ls_totales-totgalones.

        TRANSLATE ls_cab-plvehiculo TO UPPER CASE.

        WRITE: ls_cab-galones TO ls_cab-galones NO-GROUPING DECIMALS 2 NO-GAP.

        CONDENSE: ls_cab-oepesotot NO-GAPS,
                  ls_cab-oeimptot NO-GAPS,
                  ls_cab-oecantot NO-GAPS,
                  ls_cab-galones NO-GAPS.

        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
          EXPORTING
            input  = ls_cab-oecantot
          IMPORTING
            output = ls_cab-oecantot.

        APPEND ls_cab TO ti_report.

        CLEAR lv_json.

        zcl_json_utility=>convert_stuct_to_json(
          EXPORTING
             im_s_data = ls_cab
             im_v_case = zcl_json_utility=>co_ftype_camelcase
          RECEIVING
             rt_v_json = lv_json ).

        IF sy-uname EQ '700-009'.
          cl_demo_output=>display( lv_json ).
          lv_men_1 = |OE No procesada|.

          IF sy-sysid NE gc_sistema.
*            BREAK-POINT.
            RETURN.
          ENDIF.
        ENDIF.

        IF lv_json IS INITIAL.

**** Falta agregar el mensaje de error
          RETURN.
        ELSE.
*          BREAK-POINT.
          lv_jsonoe = |{ lv_jsonoe } { lv_json }|.
          IF lv_rec NE 0.
            lv_jsonoe = |{ lv_jsonoe },|.
          ENDIF.
        ENDIF.

      ENDIF.

      CLEAR ls_docdig.
    ENDLOOP.

    lv_jsonoe = |{ lv_jsonoe } ]|.

    IF sy-subrc EQ 0.
      ev_json = lv_jsonoe.
      mv_json_oe = lv_jsonoe.

      rv_return = abap_true.
    ELSE.
*      technical_message = 'No se genero la estructura JSON'.
    ENDIF.
  ENDMETHOD.

  METHOD set_char_esp.
    CALL FUNCTION 'SCP_REPLACE_STRANGE_CHARS'
      EXPORTING
        intext            = iv_string
      IMPORTING
        outtext           = ev_string
      EXCEPTIONS
        invalid_codepage  = 1
        codepage_mismatch = 2
        internal_error    = 3
        cannot_convert    = 4
        fields_not_type_c = 5
        OTHERS            = 6.

    IF sy-subrc <> 0.

*   MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDMETHOD.

  METHOD create_json_consolidado.
    CONSTANTS:
      lc_gc           TYPE string VALUE 'GC',
      lc_fac          TYPE string VALUE 'FAC',
      lc_oe           TYPE string VALUE 'OE',
      lc_ini_llave(1) TYPE c VALUE '{',
      lc_fin_llave(1) TYPE c VALUE '}',
      lc_ini_cor(1)   TYPE c VALUE '[',
      lc_fin_cor(1)   TYPE c VALUE ']',
      lc_dob_comi(1)  TYPE c VALUE '"'.

*    DATA(lv_id) = | { lc_dob_comi }id{ lc_dob_comi }:|.
    DATA(lv_gc) = |{ lc_dob_comi }{ lc_gc }{ lc_dob_comi }: |.

    rv_json = |{ lc_ini_cor } { lc_ini_llave } { lv_gc } { iv_json_gc } { lc_fin_llave }, |.

    DATA(lv_fac) = |{ lc_dob_comi }{ lc_fac }{ lc_dob_comi }: |.
    rv_json = |{ rv_json } { lc_ini_llave } { lv_fac } { iv_json_fac } { lc_fin_llave } |.

    IF iv_json_oe IS NOT INITIAL.
      rv_json = | { rv_json },|.
      DATA(lv_oe) = |{ lc_dob_comi }{ lc_oe }{ lc_dob_comi }: |.
      rv_json = |{ rv_json } { lc_ini_llave } { lv_oe } { iv_json_oe } { lc_fin_llave } |.
    ENDIF.

    rv_json = |{ rv_json }{ lc_fin_cor }|.
  ENDMETHOD.

*  METHOD get_url.
*
*  ENDMETHOD.

  METHOD proccess_rxp.
    DATA:
      lv_json_desp TYPE string,
      lv_json_fact TYPE string,
      lv_json_oe   TYPE string,
      lt_destino   TYPE tt_destino,
      lr_tknum     TYPE RANGE OF vttk-tknum.

    DATA(lo_rxp) = NEW zcl_sd_desp_digital( ).

    TRY.
        DATA(lo_docdig) = NEW zcl_sd_doc_digital( ).
      CATCH cx_abap_invalid_value.
*              out->write( | Carrier { c_carrier_id } does not exist | ).
    ENDTRY.

    CLEAR: lv_json_desp, lv_json_fact, lv_json_oe.

    IF lo_rxp->check_desp(
         EXPORTING
           iv_tplst  = ms_guia-tplst
           iv_tknum  = ms_guia-tknum ) EQ abap_false.

*      ev_process_result = zcl_sd_doc_digital=>wr_not_head_trans.
*      ev_technical_message = zcl_sd_doc_digital=>technical_message.
*      et_message[] = zcl_sd_doc_digital=>lt_message.
      EXIT.
    ENDIF.

*    LOOP AT lt_vttk INTO DATA(ls_vttk).
    APPEND VALUE #( sign = 'I' option = 'EQ' low = ms_guia-tknum )
            TO lr_tknum.
*    ENDLOOP.

    IF lo_rxp->get_desp_enc(
       EXPORTING
*         iv_tplst  = ms_guia-tplst
         is_desp = ms_guia
         iv_proccess = mv_proccess
         is_dat_gc   = ms_dat_gc
       IMPORTING
         et_table  = lt_head_rxp[] ) EQ abap_false.

*      ev_process_result = zcl_sd_doc_digital=>wr_not_head_trans.
*      ev_technical_message = zcl_sd_doc_digital=>technical_message.
*      et_message[] = zcl_sd_doc_digital=>lt_message.
      EXIT.
    ENDIF.

    IF lo_rxp->get_gc_items(
       EXPORTING
         iv_tknum  = ms_guia-tknum
         iv_proccess = mv_proccess
       IMPORTING
         et_table  = lt_items[] ) EQ abap_false.

*      ev_process_result = zcl_sd_doc_digital=>wr_not_exit_mer.
*      ev_technical_message = zcl_sd_doc_digital=>technical_message.
*      et_message[] = zcl_sd_doc_digital=>lt_message.
      EXIT.
    ENDIF.

**    ev_process_result = zcl_sd_doc_digital=>ok_trans.
*
    IF lo_rxp->get_destino(
      EXPORTING
        it_table = lt_items[]
      CHANGING
        et_table = lt_head_rxp[] ) EQ abap_false.
*      ev_process_result = zcl_sd_doc_digital=>wr_not_exit_dest.
*      ev_technical_message = zcl_sd_doc_digital=>technical_message.
*      et_message[] = zcl_sd_doc_digital=>lt_message.
      EXIT.
    ENDIF.

    " Validar que tenga transporte asignado
*    IF lo_rxp->check_transporte(
*      EXPORTING
*        it_table = lt_head_rxp ) EQ abap_false.
**      ev_process_result = zcl_sd_doc_digital=>wr_transportista.
**      ev_technical_message = zcl_sd_doc_digital=>technical_message.
**      et_message[] = zcl_sd_doc_digital=>lt_message.
*      EXIT.
*    ENDIF.

    IF lo_rxp->set_group_gc(
      EXPORTING
        iv_document = mv_proccess
        it_head     = lt_head_rxp[]
        it_items    = lt_items[]
      IMPORTING
        et_head     = lt_gc_headrxp[]
        et_items    = lt_gc_items[]
        et_gck      = lt_gck[]
        et_gcp      = lt_gcp[] ) EQ abap_false.

*      ev_technical_message = zcl_sd_doc_digital=>technical_message.
*      ev_process_result = zcl_sd_doc_digital=>er_create_json.
*      et_message[] = zcl_sd_doc_digital=>lt_message.
      EXIT.
    ENDIF.

*    t_head[] = lt_gc_head[].
*    t_items[] = lt_gc_items[].

    IF mv_view = abap_true.
*      sy-uname EQ '700-009.
      cl_demo_output=>display( lt_gc_headrxp[] ).
      cl_demo_output=>display( lt_gc_items[] ).
    ENDIF.

    CLEAR lt_destino.

    IF lo_rxp->create_json_gc(
      EXPORTING
        iv_document = mv_proccess
        it_head     = lt_gc_headrxp[]
        it_items    = lt_gc_items[]
      IMPORTING
        ev_json     = lv_json_desp
      CHANGING
        et_destino  = lt_destino[] ) EQ abap_false.

*      ev_technical_message = zcl_sd_doc_digital=>technical_message.
*      et_message[] = zcl_sd_doc_digital=>lt_message.
*      ev_process_result = zcl_sd_doc_digital=>er_create_json.
      EXIT.

    ENDIF.

    IF mv_view EQ abap_true.
      cl_demo_output=>display( lv_json_desp ).
    ENDIF.

*    et_message[] = zcl_sd_doc_digital=>lt_message.
*    ev_process_result = zcl_sd_doc_digital=>ok_send_gc.
*

* Crea el Json de Factura
    create_json_fac(
      EXPORTING
        it_fac  = lt_items[]
      IMPORTING
        ev_json = lv_json_fact ).

    DATA: lt_oe_head  TYPE STANDARD TABLE OF zview_entrega_oe,
          lt_oe_items TYPE STANDARD TABLE OF zview_entp_oe,
          lt_head_oe  TYPE STANDARD TABLE OF zview_entrega_oe,
          lt_items_oe TYPE STANDARD TABLE OF zview_entp_oe.

** particionas las paginas de las ordenes de entrega
*    IF iv_orden = 'GD'.
*      DATA(lv_orden) = 'LR'.
*    ELSE.
*      lv_orden = 'OE'.
*    ENDIF.
*
* Busca todos las ordene de Entregas asociadas al transporte
    IF lo_docdig->get_transp_oe(
     EXPORTING
       iv_tplst  = ms_guia-tplst
       it_tknum  = lr_tknum[]
       iv_orddev = mv_proccess
     IMPORTING
       et_head  = lt_oe_head[]
       et_items = lt_oe_items[] ) EQ abap_false.

    ENDIF.

    IF lt_oe_head[] IS NOT INITIAL.

      IF lo_docdig->send_oe(
                EXPORTING
                  iv_document = mv_proccess
                  it_head     = lt_oe_head[]
                  it_items    = lt_oe_items[]
                IMPORTING
                  et_head     = lt_head_oe[]
                  et_items    = lt_items_oe[] ) EQ abap_false.

      ENDIF.

      IF create_json_oe(
          EXPORTING
            iv_document = mv_proccess "iv_orden
*          iv_fecdoc   = lv_fecpro
            it_head     = lt_head_oe[] "t_oe_head[]
            it_items    = lt_items_oe[] "t_oe_items[]
            it_destino  = lt_destino[]
            it_items_gc = lt_items[]
          IMPORTING
            ev_json     = lv_json_oe ) EQ abap_false.
        EXIT.
      ENDIF.
    ENDIF.

    mv_json = lv_json_desp.
    mv_json_fac = lv_json_fact.
    mv_json_oe = lv_json_oe.

    mv_json_con = create_json_consolidado(
      EXPORTING
        iv_json_gc  = lv_json_desp
        iv_json_fac = lv_json_fact
        iv_json_oe  = lv_json_oe ).

  ENDMETHOD.

ENDCLASS.
