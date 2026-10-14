*  FECHA DE CREACION: 15.09.2026
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : CLASS
*  ORDEN          : DR3K97
*  Solicitud      : REQ-1354
*&---------------------------------------------------------------------*
*   Descripción
*   Envío de despacho digitales
*
*&---------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
* Fecha       Caso   User    Orden       Descripción
*
*&--------------------------------------------------------------------*
CLASS zcl_sd_desp_digital DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPE-POOLS abap.

    CONSTANTS: ok_send_gc         TYPE char5 VALUE 'OK001',
               ok_request_200     TYPE char5 VALUE 'OK200',
               ok_send_oe         TYPE char5 VALUE 'OK003',
               ok_access_expanded TYPE char5 VALUE 'OK004',
               ok_trans           TYPE char5 VALUE 'OK005'.

    CONSTANTS: wr_not_head_trans TYPE char5 VALUE 'WR01',
               wr_not_exit_mer   TYPE char5 VALUE 'WR02',
               wr_not_exit_dest  TYPE char5 VALUE 'WR03',
               wr_transportista  TYPE char5 VALUE 'WR04'.

    CONSTANTS: er_exists                     TYPE char5 VALUE 'ER01',
               er_request_404                TYPE char5 VALUE 'ER404',
               er_not_implemented            TYPE char5 VALUE 'ER501',
               er_create_json                TYPE char5 VALUE 'ER001',
               er_not_items_trans            TYPE char5 VALUE 'ER05',
               er_not_access_service         TYPE char5 VALUE 'ER06',
               er_unknown_process            TYPE char5 VALUE 'ER07',
               er_user_lock                  TYPE char5 VALUE 'ER08',
               er_http_communication_failure TYPE char5 VALUE 'ER09',
               er_http_invalid_state         TYPE char5 VALUE 'ER10',
               er_http_processing_failed     TYPE char5 VALUE 'ER11'.

    CONSTANTS: gc_sistema     TYPE string VALUE 'QR3',
               gc_dest_dist   TYPE string VALUE 'recepcion_digital_crp@corimon.com',
               gc_status_e(1) TYPE c VALUE 'E'.
*               gc_parvw       TYPE parvw VALUE 'WE'.

* Guía de Carga
    TYPES: ty_gc_head TYPE STANDARD TABLE OF zv_sd_gd_rxp, "zv_cds_sd_gc,
           ty_gc_item TYPE STANDARD TABLE OF zv_cds_gcp,
           ty_gck     TYPE STANDARD TABLE OF zsd_tb_gck,
           ty_gcp     TYPE STANDARD TABLE OF zsd_tb_gcp.

    TYPES: ty_transp_head TYPE STANDARD TABLE OF zview_entrega_oe,
*           ty_oe_head TYPE STANDARD TABLE OF zview_entrega_oe,
           ty_oe_item     TYPE STANDARD TABLE OF zview_entp_oe,
           ty_likp_oe     TYPE STANDARD TABLE OF zsd_likp_oe.

    TYPES: tyr_tknum      TYPE RANGE OF vttk-tknum,
           tyr_nroentrega TYPE RANGE OF likp-vbeln.

    TYPES:
      BEGIN OF ty_guia,
        tplst  TYPE tplst,
        tknum  TYPE tyr_tknum,
        dig_sl TYPE abap_bool,
      END OF ty_guia,

*      tt_desp  TYPE ty_guia,

      BEGIN OF ty_desp,
        tplst  TYPE tplst,
        tknum  TYPE tknum,
        dig_sl TYPE abap_bool,
      END OF ty_desp,

      BEGIN OF ty_nroentrega,
        sign     TYPE /bcv/fnd_sign_range,
        option   TYPE /bcv/fnd_option,
        low(10)  TYPE c,
        high(10) TYPE c,
      END OF ty_nroentrega,

      BEGIN OF ty_tknum,
        sign     TYPE /bcv/fnd_sign_range,
        option   TYPE /bcv/fnd_option,
        low(10)  TYPE c,
        high(10) TYPE c,
      END OF ty_tknum,

      BEGIN OF ty_dat_gc,
        ord_dev     TYPE string,
        ord_equi    TYPE string,
        precintos   TYPE string,
        not_cred    TYPE string,
        despachador TYPE string,
      END OF ty_dat_gc,

      BEGIN OF ty_smtp,
        smtp_addr TYPE adr6-smtp_addr,
      END OF ty_smtp,

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

      BEGIN OF ty_range,
        sign     TYPE /bcv/fnd_sign_range,
        option   TYPE /bcv/fnd_option,
        low(10)  TYPE c,
        high(10) TYPE c,
      END OF ty_range,

      tt_range TYPE STANDARD TABLE OF ty_range.

    TYPES: tt_lines TYPE STANDARD TABLE OF tline WITH DEFAULT KEY.

    TYPES tt_receiver TYPE STANDARD TABLE OF adr6-smtp_addr.

    DATA: mv_men_1 TYPE symsgv,
          mv_men_2 TYPE symsgv,
          lt_lfart TYPE tt_range.

    DATA: mv_tplst TYPE tplst READ-ONLY,
          mt_tkum  TYPE tyr_tknum READ-ONLY,
          ms_desp  TYPE ty_guia READ-ONLY,
          mv_view  TYPE abap_bool VALUE abap_false READ-ONLY.

    CLASS-DATA: technical_message TYPE string,
                ls_message        TYPE          symsg,
                lt_message        TYPE TABLE OF symsg.

    CLASS-METHODS:
*      create_json_gc
*        IMPORTING
*          iv_document      TYPE c
*          !it_head         TYPE ty_gc_head
*          !it_items        TYPE ty_gc_item
*        EXPORTING
*          ev_json          TYPE string
*        CHANGING
*          et_destino       TYPE tt_destino  "zsd_tt_oe
*        RETURNING
*          VALUE(rv_return) TYPE abap_bool,

      create_json_oe IMPORTING iv_document      TYPE c
                               iv_fecdoc        TYPE sy-datum
                               !it_head         TYPE ty_transp_head
                               !it_items        TYPE ty_oe_item
                     EXPORTING ev_json          TYPE string
                     RETURNING VALUE(rv_return) TYPE abap_bool.

    METHODS:
      constructor
        IMPORTING
          iv_view TYPE abap_bool OPTIONAL,
*          is_desp TYPE ty_guia,

      init
        IMPORTING
          is_desp TYPE ty_guia,

      create_json_gc
        IMPORTING
          iv_document      TYPE c
          !it_head         TYPE ty_gc_head
          !it_items        TYPE ty_gc_item
        EXPORTING
          ev_json          TYPE string
        CHANGING
          et_destino       TYPE tt_destino  "zsd_tt_oe
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

*      get_guia_carga,

      get_desp_enc
        IMPORTING
          is_desp          TYPE ty_desp
*          iv_tplst         TYPE tplst
*          iv_tknum         TYPE tknum
          iv_proccess      TYPE c
          is_dat_gc        TYPE zsd_st_datos_gc
        EXPORTING
          et_table         TYPE ANY TABLE
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      get_gc_items
        IMPORTING
          iv_tknum         TYPE tknum "tyr_tknum
          iv_proccess      TYPE c
        EXPORTING
          et_table         TYPE ty_gc_item
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      get_serv_dana IMPORTING iv_process       TYPE c
                              iv_json          TYPE string
                              iv_tplst         TYPE tplst
                    EXPORTING ev_response      TYPE zsd_st_json_status
                    CHANGING  es_docdig        TYPE zsd_likp_oe OPTIONAL
                              es_gc            TYPE zsd_tb_gcp OPTIONAL
                              cs_log           TYPE zsd_tb_oe_log
                    RETURNING VALUE(rv_return) TYPE abap_bool,

      get_destino
        IMPORTING
          it_table         TYPE ty_gc_item
        CHANGING
          et_table         TYPE ty_gc_head
        RETURNING
          VALUE(rv_return) TYPE abap_bool,

      check_transporte IMPORTING it_table         TYPE ty_gc_head
                       RETURNING VALUE(rv_return) TYPE abap_bool,

      check_desp IMPORTING iv_tplst         TYPE tplst
                           iv_tknum         TYPE tknum
*                         !it_table        TYPE ty_gc_head
                 RETURNING VALUE(rv_return) TYPE abap_bool,

      get_transp_oe IMPORTING iv_tplst         TYPE tplst
                              it_tknum         TYPE tyr_tknum
                              iv_orddev        TYPE c OPTIONAL
                    EXPORTING et_head          TYPE ty_transp_head "ANY TABLE
                              et_items         TYPE ty_oe_item "ANY TABLE
                    RETURNING VALUE(rv_return) TYPE abap_bool,

      send_oe IMPORTING iv_document      TYPE c
                        it_head          TYPE ty_transp_head
                        it_items         TYPE ty_oe_item
              EXPORTING et_head          TYPE ty_transp_head
                        et_items         TYPE ty_oe_item
*                        ev_json          TYPE string
              RETURNING VALUE(rv_return) TYPE abap_bool,

      check_date IMPORTING iv_bukrs         TYPE bukrs
                 EXPORTING ev_fecpro        TYPE sy-datum
                 RETURNING VALUE(rv_return) TYPE abap_bool,

      val_transp_oe IMPORTING it_table         TYPE ty_transp_head
                    RETURNING VALUE(rv_return) TYPE abap_bool,

      check_pend_oe IMPORTING it_table         TYPE ty_transp_head
                    RETURNING VALUE(rv_return) TYPE abap_bool,

      check_oe_gen IMPORTING iv_tknum         TYPE tknum "tyr_tknum
                             it_entrega       TYPE tyr_nroentrega " ty_nroentrega
                   EXPORTING ev_mensaje       TYPE symsgv
                   CHANGING
                             et_gc            TYPE ty_gc_item
                   RETURNING VALUE(rv_return) TYPE abap_bool,

      set_group_gc
        IMPORTING
          iv_document      TYPE c
          it_head          TYPE ty_gc_head
          it_items         TYPE ty_gc_item
        EXPORTING
          et_head          TYPE ty_gc_head
          et_items         TYPE ty_gc_item
          et_gck           TYPE ty_gck
          et_gcp           TYPE ty_gcp
        RETURNING
          VALUE(rv_return) TYPE abap_bool.

  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS: lc_spras(1) TYPE c VALUE 'S'.

******** DAtos de Soluciones laser  '''''
    CONSTANTS:
      lc_url      TYPE string VALUE 'https://wsqados.solucioneslaser.com/CorimonCarga/recursos/documento/corimonCarga',
      lc_username TYPE string VALUE 'user',
      lc_password TYPE string VALUE 'clave123'.
******************************************

    DATA: lv_name       TYPE thead-tdname,
          lt_lines      TYPE TABLE OF tline,
          lv_espacio(4) TYPE c.

    DATA: lt_text   TYPE STANDARD TABLE OF tline,
          wa_header TYPE thead.

    DATA:
      ls_return TYPE          bapiret2,
      lt_return TYPE TABLE OF bapiret2.

    TYPES: ty_html_text TYPE TABLE OF htmlline.

    TYPES:
      BEGIN OF st_docdig,
        tdocumento   TYPE ztdocumento,
        nrodocumento TYPE znrodocumento,
        pag          TYPE zpagina,
      END OF st_docdig.

    DATA:
      gt_receiver TYPE tt_receiver,
      lt_nc       TYPE tt_range.

    METHODS:
      commit_work,

      set_bapi_message   IMPORTING it_return_table TYPE bapirettab,

      set_message   IMPORTING it_return_table TYPE bst_symsgs,

      get_datos_cabecera IMPORTING iv_tknum         TYPE tknum
                                   iv_proccess      TYPE c
                                   is_dat_gc        TYPE zsd_st_datos_gc
                         CHANGING  !es_item         TYPE zv_sd_gd_rxp "zv_cds_sd_gc
                                   ev_mensaje       TYPE symsgv
                                   !et_table        TYPE ty_gc_head OPTIONAL
                         RETURNING VALUE(rv_return) TYPE abap_bool,

      get_texto          IMPORTING iv_id     TYPE thead-tdid
                                   iv_object TYPE thead-tdobject
                                   iv_name   TYPE thead-tdname
                         EXPORTING ev_name   TYPE tdline,

      get_tot_enc        IMPORTING it_table   TYPE ty_gc_head
                         EXPORTING ev_totkilo TYPE zpesototal
                                   ev_paletas TYPE zpaletas,

      get_oe_items IMPORTING !it_table        TYPE ty_transp_head
                   EXPORTING !et_table        TYPE ty_oe_item
                   RETURNING VALUE(rv_return) TYPE abap_bool,

      set_char_esp IMPORTING iv_string TYPE c
                   EXPORTING ev_string TYPE c,

      upd_status_oe IMPORTING iv_status  TYPE c
                    CHANGING  !is_docdig TYPE zsd_likp_oe,

      upd_status_gc IMPORTING iv_status  TYPE c
                    CHANGING  !is_docdig TYPE zsd_tb_gcp,

      set_log IMPORTING !is_oe_log TYPE zsd_tb_oe_log,

      clear_log,

      close_http IMPORTING io_http_client TYPE REF TO if_http_client,

      get_banner IMPORTING iv_tpls          TYPE tplst
                           iv_fecha         TYPE sy-datum
                 RETURNING VALUE(rv_banner) TYPE zbanners,

      get_dif_peso IMPORTING iv_vbeln         TYPE vbeln
                             iv_doc           TYPE c
                   CHANGING  !es_gc           TYPE zv_cds_gcp
                   RETURNING VALUE(rv_return) TYPE abap_bool,

      send_msg_mail IMPORTING iv_process TYPE c OPTIONAL
                              iv_tplst   TYPE tplst
                              iv_asunto  TYPE so_obj_des
                              !is_oe_log TYPE zsd_tb_oe_log,

      find_email_address IMPORTING iv_tplst   TYPE tplst
                                   !is_oe_log TYPE zsd_tb_oe_log
                         EXPORTING !et_addr   TYPE tt_receiver,

      read_body_mail
        EXPORTING es_header TYPE thead
                  et_lines  TYPE tt_lines,

      get_det_error
        IMPORTING iv_tplst      TYPE tplst
                  !is_oe_log    TYPE zsd_tb_oe_log
        CHANGING  et_body_email TYPE ty_html_text.

ENDCLASS.

CLASS zcl_sd_desp_digital IMPLEMENTATION.

  METHOD constructor.
    me->mv_view = iv_view.

    lt_lfart = VALUE #(
*            ( option = 'EQ' sign = 'I' low = 'NL' )
            ( option = 'EQ' sign = 'I' low = 'ZECN' ) ).

*    lt_nc = VALUE #(
*            ( option = 'EQ' sign = 'I' low = 'LR' ) ).

  ENDMETHOD.

  METHOD init.

    me->ms_desp = is_desp.

    lt_lfart = VALUE #(
*            ( option = 'EQ' sign = 'I' low = 'NL' )
            ( option = 'EQ' sign = 'I' low = 'ZECN' ) ).

*    lt_nc = VALUE #(
*            ( option = 'EQ' sign = 'I' low = 'LR' ) ).

  ENDMETHOD.

  METHOD commit_work.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

  METHOD set_bapi_message.
    CHECK it_return_table IS NOT INITIAL.

    READ TABLE it_return_table INTO DATA(ls_return) INDEX 1.

    IF sy-subrc EQ 0.
      technical_message = ls_return-message.
    ENDIF.

  ENDMETHOD.

  METHOD set_message.
    CHECK it_return_table IS NOT INITIAL.

    READ TABLE it_return_table INTO DATA(ls_return) INDEX 1.

    IF sy-subrc EQ 0.
      technical_message = ls_return-msgv1.
      IF NOT ls_return-msgv2 IS INITIAL.
        CONCATENATE technical_message ls_return-msgv2
              INTO technical_message SEPARATED BY space.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD get_desp_enc.
*    DATA: lt_head TYPE STANDARD TABLE OF zv_cds_sd_gc.
*    DATA: ls_head TYPE zv_cds_sd_gc.
    DATA:
      lt_head TYPE STANDARD TABLE OF zv_sd_gd_rxp,
      ls_head TYPE zv_sd_gd_rxp.

    CLEAR technical_message.

    CLEAR: me->ls_message, me->ls_return, me->lt_return.

*    SELECT SINGLE route
*    FROM zsd_tb_serv_tran
*    INTO @DATA

    SELECT *
      FROM zcds_sd_gd_rxp( p_tplst = @is_desp-tplst )
      INTO TABLE @DATA(lt_trans_head)
     WHERE nrotrans EQ @is_desp-tknum AND
           type_serv EQ 'P'.

    IF sy-subrc EQ 0.
      LOOP AT lt_trans_head ASSIGNING FIELD-SYMBOL(<lfs_trans_head>).
        CLEAR ls_head.

*        ls_head-nrotrans = <lfs_trans_head>-nrotrans.
*        ls_head-femision = <lfs_trans_head>-femision.
*        ls_head-hemision = <lfs_trans_head>-hemision.
*        ls_head-tplst = <lfs_trans_head>-tplst.
*        ls_head-vsart = <lfs_trans_head>-vsart.
*        ls_head-tdlnr = <lfs_trans_head>-tdlnr.
**        ls_head-frkrl = <lfs_trans_head>-frkrl.
**        ls_head-acepservicio = <lfs_trans_head>-acepservicio.
*        ls_head-adrnr = <lfs_trans_head>-adrnr.
*        ls_head-puesto = <lfs_trans_head>-puesto.
**        ls_head-tipveh = <lfs_trans_head>-tipveh.
*        ls_head-pais = <lfs_trans_head>-pais.
*        ls_head-transp = <lfs_trans_head>-transp.
**        ls_head-nrohoja = <lfs_trans_head>-nrohoja.
**        ls_head-venum = <lfs_trans_head>-venum.
**        ls_head-paleta = <lfs_trans_head>-paleta.
**        ls_head-kulab = <lfs_trans_head>-kulab.
*        ls_head-preparador = <lfs_trans_head>-preparador.
*        ls_head-supervisor = <lfs_trans_head>-supervisor.
*        ls_head-orddev = is_dat_gc-ord_dev.
*        ls_head-ordequi = is_dat_gc-ord_equi.
*        ls_head-observaciones = <lfs_trans_head>-observaciones.
*        ls_head-notcred = is_dat_gc-nota_cred.
*        ls_head-precintos = is_dat_gc-precintos.
*        ls_head-despachador = is_dat_gc-despachador.
*        ls_head-gesztd = <lfs_trans_head>-gesztd.
*        ls_head-tdlnr = <lfs_trans_head>-rif_rxp.

        ls_head = VALUE #( nrotrans = <lfs_trans_head>-nrotrans
                           femision = <lfs_trans_head>-femision
                           hemision = <lfs_trans_head>-hemision
                           tplst = <lfs_trans_head>-tplst
                           vsart = <lfs_trans_head>-vsart
                           tdlnr = <lfs_trans_head>-rif_rxp
*                           ls_head-frkrl = <lfs_trans_head>-frkrl.
*                           ls_head-acepservicio = <lfs_trans_head>-acepservicio.
                           adrnr = <lfs_trans_head>-adrnr
                           puesto = <lfs_trans_head>-puesto
                           tipveh = <lfs_trans_head>-tipveh
                           pais = <lfs_trans_head>-pais
                           transp = <lfs_trans_head>-transp
*                           ls_head-nrohoja = <lfs_trans_head>-nrohoja.
*                           ls_head-venum = <lfs_trans_head>-venum.
*                           ls_head-paleta = <lfs_trans_head>-paleta.
*                           ls_head-kulab = <lfs_trans_head>-kulab.
                           preparador = <lfs_trans_head>-preparador
                           supervisor = <lfs_trans_head>-supervisor
                           orddev = is_dat_gc-ord_dev
                           ordequi = is_dat_gc-ord_equi
                           observaciones = <lfs_trans_head>-observaciones
                           notcred = is_dat_gc-nota_cred
                           precintos = is_dat_gc-precintos
                           despachador = is_dat_gc-despachador
                           gesztd = <lfs_trans_head>-gesztd
                           rif_rxp = <lfs_trans_head>-rif_rxp
                           correotransp = <lfs_trans_head>-correo_rxp
                           correo = <lfs_trans_head>-correo
                           type_serv = <lfs_trans_head>-type_serv ).

        APPEND ls_head TO lt_head.

*        IF iv_proccess = 'GC'.
*          IF <lfs_trans_head>-frkrl EQ 'X'.
*            IF ls_head-acepservicio IS INITIAL.
*              mv_men_1 = 'El gasto de transporte,'.
*              mv_men_2 = 'no tiene aceptación de servicio'.
*              ls_message = VALUE symsg( msgty = 'W'
*                                  msgid = '11'
*                                  msgno = '011'
*                                  msgv1 = mv_men_1
*                                  msgv2 = mv_men_2 ).
*
*              APPEND ls_message TO lt_message.
*
*              me->set_message( lt_message ).
*              EXIT.
*            ENDIF.
*          ENDIF.
*        ENDIF.

        IF me->get_datos_cabecera(
          EXPORTING
            iv_tknum  = ls_head-nrotrans
            iv_proccess = iv_proccess
            is_dat_gc = is_dat_gc
          CHANGING
            es_item  = ls_head
            ev_mensaje = mv_men_2
            et_table = lt_head ) EQ abap_false.

*          ls_message = VALUE symsg( msgty = 'W'
*                          msgid = '10'
*                          msgno = '010'
*                          msgv1 = 'Complete la información del Transportista:'
*                          msgv2 = mv_men_2 ).
*
*          APPEND ls_message TO lt_message.
*
*          me->set_message( lt_message ).
*
*          EXIT.
        ENDIF.

        IF ls_head-correotransp IS INITIAL.
          ls_message = VALUE symsg( msgty = 'W'
                            msgid = '10'
                            msgno = '010'
                            msgv1 = 'La empresa de transporte le falta correo' ).

          APPEND ls_message TO lt_message.

          me->set_message( lt_message ).
          EXIT.
        ENDIF.

*        IF ls_head-correo IS INITIAL.
*          ls_message = VALUE symsg( msgty = 'W'
*                            msgid = '10'
*                            msgno = '010'
*                            msgv1 = 'Al chofer le falta dirección de correo' ).
*
*          APPEND ls_message TO lt_message.
*
*          me->set_message( lt_message ).
*          EXIT.
*        ENDIF.

      ENDLOOP.

      rv_return = abap_true.

    ENDIF.

    IF lt_head[] IS INITIAL.
      ls_message = VALUE symsg( msgty = 'W'
                                msgid = '01'
                                msgno = '001'
                                msgv1 = 'Verifique la Guía de Carga' ).

      APPEND ls_message TO lt_message.

      me->set_message( lt_message ).
    ENDIF.

    et_table[] = lt_head[].
  ENDMETHOD.

  METHOD get_gc_items.
    CONSTANTS lc_enviado TYPE na_vsztp VALUE '1'.

    DATA: lt_items       TYPE STANDARD TABLE OF zv_cds_gcp,
          lt_items_check TYPE STANDARD TABLE OF zv_cds_gcp,
          lt_head_oe     TYPE STANDARD TABLE OF zview_entrega_oe.

    DATA: ls_item    TYPE zv_cds_gcp,
          lt_df      TYPE STANDARD TABLE OF zview_doc_flujo,
          wa_oe_pend TYPE STANDARD TABLE OF zsd_likp_oe.

    DATA: ltr_nroentrega TYPE TABLE OF ty_nroentrega,
          lsr_nroentrega TYPE ty_nroentrega.

    DATA lv_men TYPE string.

    CLEAR technical_message.

    CLEAR: me->ls_message, me->ls_return, me->lt_return,
           mv_men_1, mv_men_2.

    CLEAR: ltr_nroentrega[].
    REFRESH ltr_nroentrega[].

    DATA(lo_facdig) = NEW zcl_enviarfactdigital( ).

    SELECT *
     FROM zsd_cds_gcp
     INTO TABLE @DATA(lt_trans_items)
    WHERE nrotrans EQ @iv_tknum.

    IF sy-subrc EQ 0.

      CASE iv_proccess.
        WHEN 'RXP'.
          ltr_nroentrega = VALUE #( FOR ls_nro IN lt_trans_items
                                      WHERE ( lfart IN lt_lfart )
                                      ( sign   = 'I'
                                        option = 'EQ'
                                        low    = ls_nro-nroentrega ) ).
*        WHEN 'GD'.
*          ltr_nroentrega = VALUE #( FOR ls_nro IN lt_trans_items
*                                      WHERE ( lfart IN lt_nc )
*                                      ( sign   = 'I'
*                                        option = 'EQ'
*                                        low    = ls_nro-nroentrega ) ).
      ENDCASE.

      IF NOT ltr_nroentrega IS INITIAL.
        SELECT *
          FROM zsd_likp_oe
         WHERE vbeln IN @ltr_nroentrega
          INTO TABLE @DATA(lt_oe_g).

        DATA lv_found TYPE abap_bool.

        DATA(lv_items) = REDUCE i( INIT cont TYPE i
                                    FOR wa IN lt_oe_g
                                        WHERE ( estado NE 'S' )
                                            NEXT cont = cont + 1 ).

        IF sy-subrc NE 0 OR lv_items GT 0.
          mv_men_1 = 'Faltan Ord. de entregas digitales por generar: '.

          LOOP AT ltr_nroentrega INTO DATA(wa_no).
            IF NOT line_exists( lt_oe_g[ vbeln = wa_no-low ] ).
              CONCATENATE mv_men_2 wa_no-low
                     INTO mv_men_2 SEPARATED BY space.
            ENDIF.
          ENDLOOP.

          ls_message = VALUE symsg( msgty = 'W'
                                  msgid = '03'
                                  msgno = '003'
                                  msgv1 = mv_men_1
                                  msgv2 = mv_men_2 ).

          APPEND ls_message TO lt_message.

          me->set_message( lt_message ).

        ELSE.
          " Valida si tiene salida de Mercancía
          IF me->check_oe_gen(
            EXPORTING
              iv_tknum   = iv_proccess " it_tknum[]
              it_entrega = ltr_nroentrega[]
              IMPORTING
              ev_mensaje = mv_men_1
            CHANGING
              et_gc = lt_items_check ) EQ abap_false AND
              iv_proccess EQ iv_proccess.

            LOOP AT lt_items_check INTO ls_item.
              CONCATENATE mv_men_2 ls_item-nroentrega
                     INTO mv_men_2 SEPARATED BY space.
            ENDLOOP.

            ls_message = VALUE symsg( msgty = 'W'
                                 msgid = '03'
                                 msgno = '003'
                                 msgv1 = mv_men_1
                                 msgv2 = mv_men_2 ).

            APPEND ls_message TO lt_message.

            me->set_message( lt_message ).

            EXIT.
          ENDIF.

          SORT lt_oe_g BY vbeln ASCENDING.

          wa_oe_pend = VALUE #( FOR ls_oe_g IN lt_oe_g
                                  WHERE ( estado NE 'S' )
                                   ( vbeln = ls_oe_g-vbeln ) ).

          IF NOT wa_oe_pend IS INITIAL.

            DELETE ADJACENT DUPLICATES FROM wa_oe_pend COMPARING vbeln.

            mv_men_1 = 'Faltan entregas por generar: '.

            LOOP AT wa_oe_pend INTO DATA(wa_pend).
              CONCATENATE mv_men_2 wa_pend-vbeln
              INTO mv_men_2 SEPARATED BY space.
            ENDLOOP.

            ls_message = VALUE symsg( msgty = 'W'
                                    msgid = '03'
                                    msgno = '003'
                                    msgv1 = mv_men_1
                                    msgv2 = mv_men_2 ).

            APPEND ls_message TO lt_message.

            me->set_message( lt_message ).
          ENDIF.

        ENDIF.
      ENDIF.

      LOOP AT lt_trans_items ASSIGNING FIELD-SYMBOL(<lfs_trans_items>).
        CLEAR ls_item.

        ls_item-nrotrans = <lfs_trans_items>-nrotrans.
        ls_item-nroentrega = <lfs_trans_items>-nroentrega.
        ls_item-docconcluido = <lfs_trans_items>-docconcluido.
        ls_item-isimprimir = <lfs_trans_items>-isimprimir.
        ls_item-volum = <lfs_trans_items>-volum.
        ls_item-pesototal = <lfs_trans_items>-pesototal.
        ls_item-lfart = <lfs_trans_items>-lfart.
        ls_item-bultos = <lfs_trans_items>-bultos.
        ls_item-distancia = <lfs_trans_items>-distancia.
        ls_item-dircliente = <lfs_trans_items>-dircliente.
        ls_item-adrnr = <lfs_trans_items>-adrnr.
        ls_item-nomcliente = <lfs_trans_items>-nomcliente.
        ls_item-city1 = <lfs_trans_items>-city1.
        ls_item-region = <lfs_trans_items>-region.
* Ubicación GPS del receptor - Innovo
        ls_item-ablad = <lfs_trans_items>-ablad.
        ls_item-rifdestino = <lfs_trans_items>-rifdestino.

        REFRESH lt_df.
        CLEAR: lt_df.

        "Orden de Entrega
        IF ls_item-lfart IN lt_lfart.
          SELECT *
             FROM zview_doc_flujo( p_vbelv = @ls_item-nroentrega )
             INTO TABLE @lt_df
             WHERE vbtyp_n = 'R'.

          IF sy-subrc EQ 0.
            ls_item-nrodocumento = ls_item-nroentrega.
            me->get_dif_peso(
              EXPORTING
                iv_vbeln = ls_item-nrodocumento
                iv_doc   = gc_status_e
              CHANGING
                es_gc    = ls_item ).
          ENDIF.
        ELSE.
          "Factura
          IF lt_nc IS INITIAL.
*          ls_item-lfart NOT IN lt_nc.
            SELECT *
              FROM zview_doc_flujo( p_vbelv = @ls_item-nroentrega )
              INTO TABLE @lt_df
              WHERE vbtyp_n = 'M' OR
                    vbtyp_n = '5'.

            LOOP AT lt_df INTO DATA(ls_factura).

              lo_facdig->enviar_doc_facncnd(
                EXPORTING
*                  sociedad    = lv_    " Sociedad
                  factura     = ls_factura-ndrodocumento    " Número de documento comercial
                  enviado     = lc_enviado    " Modalidad de envío
                IMPORTING
                  error       = lv_men ).

              IF lv_men EQ '099'.
                mv_men_1 = 'Falta por digitalizar: '.

                mv_men_2 = |la factura: { ls_factura-ndrodocumento }|.

                ls_message = VALUE symsg( msgty = 'W'
                                        msgid = '03'
                                        msgno = '003'
                                        msgv1 = mv_men_1
                                        msgv2 = mv_men_2 ).

                APPEND ls_message TO lt_message.

                me->set_message( lt_message ).
              ENDIF.

            ENDLOOP.

          ELSE.
            IF ls_item-lfart IN lt_nc.
              "Ordenes de Devolución
              SELECT *
                FROM zview_doc_flujo( p_vbelv = @ls_item-nroentrega )
                INTO TABLE @lt_df
               WHERE vbtyp_n = '8'.
            ELSE.
              "Nota de Crédito 0082254420
              SELECT *
                FROM zview_doc_flujo( p_vbelv = @ls_item-nroentrega )
                INTO TABLE @lt_df
               WHERE vbtyp_n = 'O'.
            ENDIF.
          ENDIF.
        ENDIF.

        IF sy-subrc EQ 0 AND
           ls_item-lfart NOT IN lt_lfart.

          LOOP AT lt_df INTO DATA(ls_df).
            ls_item-nrodocumento = ls_df-ndrodocumento.
            CLEAR ls_item-bultos.

            SELECT SUM( fkimg )
              FROM vbrp
              INTO @DATA(lv_bultos)
             WHERE vbeln EQ @ls_df-ndrodocumento.

            IF lv_bultos GT 0.
              ls_item-bultos = lv_bultos.
            ENDIF.

            me->get_dif_peso(
              EXPORTING
                iv_vbeln = ls_item-nrodocumento
                iv_doc   = 'F'
              CHANGING
                es_gc    = ls_item ).

            APPEND ls_item TO lt_items.
          ENDLOOP.

        ENDIF.

        IF ls_item-nrodocumento IS INITIAL.
          ls_message = VALUE symsg( msgty = 'W'
                                    msgid = '02'
                                    msgno = '002'
                                    msgv1 = ls_item-nroentrega
                                    msgv2 = 'Verificar el Flujo de documentos' ).

          APPEND ls_message TO lt_message.

          me->set_message( lt_message ).
        ENDIF.

        CHECK lt_message[] IS INITIAL.

        IF ls_item-lfart IN lt_lfart OR
           ls_item-lfart IN lt_nc.

          LOOP AT lt_oe_g INTO DATA(wa_oe_g)
                          WHERE vbeln EQ ls_item-nroentrega.
            ls_item-nrodocumento = wa_oe_g-vbeln_oe.
            ls_item-pag = wa_oe_g-pag.
            ls_item-bultos = wa_oe_g-bultos.

            IF ls_item-pag NE '01'.

              ls_item-galones = 0.
              ls_item-kgcarga = 0.
              ls_item-pesototal = 0.
              ls_item-volum = 0.

            ENDIF.

            APPEND ls_item TO lt_items.

          ENDLOOP.

        ENDIF.
      ENDLOOP.

      SORT lt_items BY nrodocumento ASCENDING.

      DELETE ADJACENT DUPLICATES FROM lt_items COMPARING nrodocumento.

      DELETE lt_items
        WHERE nrodocumento EQ iv_tknum.

      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<lfs_item>).
        SELECT SINGLE bezei
          INTO <lfs_item>-estado
          FROM t005u
         WHERE spras EQ sy-langu
           AND land1 EQ 'VE'
           AND bland EQ <lfs_item>-region.
      ENDLOOP.

      SORT lt_items BY nomcliente city1 ASCENDING.

      et_table[] = lt_items[].

      IF lt_message[] IS INITIAL.
        rv_return = abap_true.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD get_serv_dana.
* El Http está configurado como rfc (SM59)
    CONSTANTS: lc_http_dest TYPE rfcdest VALUE 'FAC_DIGITAL',
               lc_asunto    TYPE so_obj_des VALUE 'Error de comunicación con servicio SL'.

    DATA:
      lv_auth_header TYPE string,
      lv_response    TYPE string.

    DATA:
      lo_http_client TYPE REF TO if_http_client,
      lo_response    TYPE REF TO if_http_response,
      ls_json_sta    TYPE zsd_st_json_status,
      ls_tb_json_sta TYPE zsd_tb_json_stat,
      lv_status_code TYPE i,
      lv_code        TYPE string,
      lv_reason      TYPE string,
      lv_tplst       TYPE tplst,
      lt_status      TYPE tt_range.

    CLEAR technical_message.

    CLEAR: me->ls_message, mv_men_1, mv_men_2, lv_tplst.

    DATA(ls_log) = VALUE zsd_tb_oe_log( sociedad   = iv_tplst
                                    tdocumento = iv_process
                                    mensaje    = ''
                                    uname      = sy-uname
                                    erdat      = sy-datum
                                    status     = '0' ).

    lt_status = VALUE #(
        ( option = 'EQ' sign = 'I' low = '0' )
        ( option = 'EQ' sign = 'I' low = '1'  ) ).

    CASE iv_process.
      WHEN 'OE' OR 'LR'.
        DATA(ls_docdig) =
            VALUE st_docdig( tdocumento   = es_docdig-tdocumento
                             nrodocumento = es_docdig-vbeln_oe
                             pag          = es_docdig-pag ).

      WHEN 'GC' OR 'GD'.
        ls_docdig = VALUE st_docdig( tdocumento   = iv_process
                                     nrodocumento = es_gc-tknum_c
                                     pag          = es_gc-pagina ).

    ENDCASE.

    ls_log-tdocumento = ls_docdig-tdocumento.
    ls_log-ndocumento = ls_docdig-nrodocumento.
    ls_log-pagina = ls_docdig-pag.

    cl_http_client=>create_by_destination(
      EXPORTING
        destination = lc_http_dest
      IMPORTING
        client     =  lo_http_client ).

    IF sy-subrc <> 0.
      ls_message = VALUE symsg( msgty = gc_status_e
                                     msgid = '01'
                                     msgno = '001'
                                     msgv1 = 'Error al crear el cliente HTTP' ).

      APPEND ls_message TO lt_message.

      set_message( lt_message  ).

      CASE iv_process.
        WHEN 'OE' OR 'LR'.
          upd_status_oe(
            EXPORTING
              iv_status = gc_status_e
            CHANGING
              is_docdig = es_docdig ).

        WHEN 'GC' OR 'GD'.
          upd_status_gc(
             EXPORTING
               iv_status = gc_status_e
             CHANGING
               is_docdig = es_gc ).

      ENDCASE.

      ls_log-mensaje = 'Error al crear el cliente HTTP'.
      ls_log-erzet = sy-uzeit.
      ls_log-status = gc_status_e.
      ls_log-fecha = sy-datum.

      set_log( is_oe_log = ls_log ).

      cs_log = ls_log.

      EXIT.
    ELSE.

      ls_log-mensaje = 'Creado el destino cliente HTTP'.
      ls_log-erzet = sy-uzeit.
      ls_log-fecha = sy-datum.

      set_log( is_oe_log = ls_log ).
    ENDIF.

    TRY.
        lo_http_client->request->set_header_field( name = '~request_method' value = 'POST' ).
* Get
        lo_http_client->request->set_cdata( iv_json ).

        lo_http_client->request->set_header_field(
          EXPORTING
            name  = 'Content-Type'
            value = 'application/json' ).

* Enviar la solicitud HTTP GET
        lo_http_client->send(
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state         = 2
            http_processing_failed     = 3
            OTHERS                     = 4 ).

        IF sy-subrc <> 0.
          ls_message = VALUE symsg( msgty = gc_status_e
                                    msgid = '01'
                                    msgno = '001'
*                                msgv1 = ls_item-nroentrega
                                    msgv1 = 'Error al enviar la solicitud HTTP' ).

          APPEND ls_message TO lt_message.

          set_message( lt_message  ).

*      WRITE: 'Error al enviar la solicitud HTTP'.
          IF iv_process = 'OE' OR
             iv_process = 'LR'.
            upd_status_oe(
              EXPORTING
                iv_status = gc_status_e
              CHANGING
                is_docdig = es_docdig ).

          ELSEIF iv_process = 'GC' OR
                 iv_process = 'GD'.
            upd_status_gc(
               EXPORTING
                 iv_status = gc_status_e
               CHANGING
                 is_docdig = es_gc ).

          ENDIF.

          ls_log-mensaje = 'Error al enviar HTTP-> GET'.
          ls_log-erzet = sy-uzeit.
          ls_log-status = gc_status_e.
          ls_log-fecha = sy-datum.

          set_log( is_oe_log = ls_log ).

          cs_log = ls_log.

          me->close_http( lo_http_client ).
          RETURN.
        ELSE.
          ls_log-mensaje = 'Enviado la solicitud HTTP->GET'.
          ls_log-erzet = sy-uzeit.
          ls_log-fecha = sy-datum.

          set_log( is_oe_log = ls_log ).
        ENDIF.

* Recibir la respuesta
        lo_http_client->receive(
          EXCEPTIONS
            http_communication_failure = 1
            http_invalid_state         = 2
            http_processing_failed     = 3
            OTHERS                     = 4 ).

        CLEAR: ls_json_sta, lv_status_code.

        IF sy-subrc <> 0.
          lo_response = lo_http_client->response.

          lv_status_code = lo_response->get_header_field('~status_code').
          lv_reason = lo_response->get_header_field( '~status_reason' ).

          IF lv_status_code EQ '500'.
            mv_men_1 = 'Certificado ha expirado'.
            mv_men_2 = 'Por favor comunicarse con TI'.
          ELSE.
            mv_men_1 = 'Error al recibir respuesta del HTTP'.
            CLEAR mv_men_2.
          ENDIF.

          ls_message = VALUE symsg( msgty = gc_status_e
                                msgid = '01'
                                msgno = '001'
                                msgv1 = mv_men_1
                                msgv2 = mv_men_2 ).

          APPEND ls_message TO lt_message.

          set_message( lt_message  ).

*      WRITE: 'Error al recibir la respuesta HTTP'.
          IF iv_process = 'OE' OR
             iv_process = 'LR'.
            upd_status_oe(
              EXPORTING
                iv_status = gc_status_e
              CHANGING
                is_docdig = es_docdig ).

*            ls_log-ndocumento = es_docdig-vbeln_oe.
*            ls_log-pagina = es_docdig-pag.
            ls_log-fecha = es_docdig-erdat.

          ELSEIF iv_process = 'GC'  OR
                 iv_process = 'GD'.
            upd_status_gc(
               EXPORTING
                 iv_status = gc_status_e
               CHANGING
                 is_docdig = es_gc ).

*            ls_log-ndocumento = es_gc-tknum_c.
*            ls_log-pagina = es_docdig-pag.
            ls_log-fecha = es_docdig-erdat.
          ENDIF.

          ls_log-mensaje = mv_men_1.
          ls_log-uname = sy-uname.
          ls_log-erdat = sy-datum.
          ls_log-erzet = sy-uzeit.
          ls_log-fecha = sy-datum.
          ls_log-status = gc_status_e.
          ls_log-fecha = sy-datum.

          set_log( is_oe_log = ls_log ).
          cs_log = ls_log.

          me->close_http( lo_http_client ).
          RETURN.
        ELSE.
          ls_log-mensaje = 'Se recibio respuesta del HTTP'.
          ls_log-erzet = sy-uzeit.
          ls_log-fecha = sy-datum.

          set_log( is_oe_log = ls_log ).
        ENDIF.

* Obtener el código de estado y la respuesta
        lo_response = lo_http_client->response.

        lv_status_code = lo_response->get_header_field('~status_code').
        lv_reason = lo_response->get_header_field( '~status_reason' ).
        lv_response = lo_http_client->response->get_cdata( ).

      CATCH cx_http_ext_exception.

        cs_log = ls_log.
        ls_log-status = gc_status_e.
    ENDTRY.

**********************transforma respuesta del json en datos internos *****************
    /ui2/cl_json=>deserialize( EXPORTING
                                 json        = lv_response
                                 pretty_name = /ui2/cl_json=>pretty_mode-camel_case
                               CHANGING
                                 data        = ls_json_sta ).
***************************************************************************************

    IF lv_status_code NE '200'.
      lv_code = lv_status_code.

      CONCATENATE 'Service' lv_reason 'Error:' lv_code
             INTO mv_men_2 SEPARATED BY space.

      ls_message = VALUE symsg( msgty = gc_status_e
                       msgid = '13'
                       msgno = lv_status_code
                       msgv1 = 'Error del servicio SL'
                       msgv2 = mv_men_2 ).

      APPEND ls_message TO lt_message.

      set_message( lt_message  ).

      IF iv_process = 'OE' OR
         iv_process = 'LR'.
        upd_status_oe(
          EXPORTING
            iv_status = gc_status_e
          CHANGING
            is_docdig = es_docdig ).

        lv_tplst = es_docdig-tplst.
      ELSEIF iv_process = 'GC' OR
             iv_process = 'GD'.
        upd_status_gc(
           EXPORTING
             iv_status = gc_status_e
           CHANGING
             is_docdig = es_gc ).

        lv_tplst = iv_tplst.
      ENDIF.

      ls_log-mensaje = mv_men_2.
      ls_log-fecha = es_gc-erdat.
      ls_log-uname = sy-uname.
      ls_log-erdat = sy-datum.
      ls_log-erzet = sy-uzeit.
      ls_log-status = gc_status_e.
      ls_log-fecha = sy-datum.

      set_log( is_oe_log = ls_log ).

      cs_log = ls_log.
      me->close_http( lo_http_client ).
      RETURN.
    ELSE.
      ls_log-mensaje = | Codigo Post: { lv_status_code }|.
      ls_log-erzet = sy-uzeit.
      ls_log-fecha = sy-datum.
*      ls_log-status = gc_status_e.

      set_log( is_oe_log = ls_log ).
*      me->close_http( lo_http_client ).
*      cs_log = ls_log.
*      RETURN.
    ENDIF.

    IF ls_json_sta-status IN lt_status AND
*         ls_json_sta-status EQ 1 )
         ls_json_sta-url IS INITIAL .

      ls_message = VALUE symsg( msgty = gc_status_e
                     msgid = '01'
                     msgno = '001'
*                            msgv1 =
                     msgv1 = 'Url está vacía' ).

      APPEND ls_message TO lt_message.

      set_message( lt_message ).

      IF iv_process = 'OE' OR
         iv_process = 'LR'.
        upd_status_oe(
          EXPORTING
            iv_status = gc_status_e
          CHANGING
            is_docdig = es_docdig ).

*        ls_log-ndocumento = es_docdig-vbeln_oe.
*        ls_log-pagina = es_docdig-pag.
      ELSEIF iv_process = 'GC' OR
             iv_process = 'GD'.
        upd_status_gc(
           EXPORTING
             iv_status = gc_status_e
           CHANGING
             is_docdig = es_gc ).

*        ls_log-ndocumento = es_gc-tknum_c.
*        ls_log-pagina = es_docdig-pag.
      ENDIF.

      ls_log-mensaje = 'Url está vacía'.
      ls_log-fecha = es_gc-erdat.
      ls_log-uname = sy-uname.
      ls_log-erdat = sy-datum.
      ls_log-erzet = sy-uzeit.
      ls_log-status = gc_status_e.
      ls_log-fecha = sy-datum.

      set_log( is_oe_log = ls_log ).

      cs_log = ls_log.
      me->close_http( lo_http_client ).

      RETURN.
* Ini 04.02.2026 481 cfalcon DR3K981056
    ELSEIF ls_json_sta-status EQ 5.
      ls_log-mensaje = ls_json_sta-mensaje.
      ls_log-fecha = sy-datum.
      ls_log-uname = sy-uname.
      ls_log-erdat = sy-datum.
      ls_log-erzet = sy-uzeit.
      ls_log-status = gc_status_e.
      ls_log-fecha = sy-datum.

      set_log( is_oe_log = ls_log ).

      cs_log = ls_log.
      me->close_http( lo_http_client ).

      RETURN.
* Fin 04.02.2026 481 cfalcon DR3K981056
    ELSE.
      ls_log-mensaje = |Creado el documento { ls_log-ndocumento } en SL.|.
      ls_log-erzet = sy-uzeit.
      ls_log-fecha = sy-datum.
*      ls_log-status = gc_status_e.

      set_log( is_oe_log = ls_log ).
      cs_log = ls_log.

    ENDIF.

    IF iv_process = 'OE' OR
       iv_process = 'LR'.
      CONCATENATE ls_json_sta-tdocumento ls_json_sta-ndocumento
                  'N° control' ls_json_sta-ncontrol
             INTO mv_men_1 SEPARATED BY space.
    ELSE.
      CONCATENATE ls_json_sta-tdocumento ls_json_sta-ndocumento
             INTO mv_men_1 SEPARATED BY space.
    ENDIF.

    ls_message = VALUE symsg( msgty = 'S'
                              msgid = '01'
                              msgno = '001'
                              msgv1 = mv_men_1
                              msgv2 = ls_json_sta-mensaje ).

    APPEND ls_message TO lt_message.

    set_message( lt_message  ).

    CASE iv_process.
      WHEN 'OE' OR 'LR'.

        es_docdig-aenam = sy-uname.
        es_docdig-aedat = sy-datum.
        es_docdig-aezet = sy-uzeit.

        CASE ls_json_sta-status.
          WHEN 0.
            upd_status_oe(
              EXPORTING
                iv_status = 'S'
              CHANGING
                is_docdig = es_docdig ).

            ls_tb_json_sta = VALUE zsd_tb_json_stat(
                bukrs      = es_docdig-tplst
                tdocumento = es_docdig-tdocumento
                vbeln      = es_docdig-vbeln_oe
                ncontrol   = ls_json_sta-ncontrol
                url        = ls_json_sta-url
                fechareci  = sy-datum
                usuario    = sy-uname ).

            INSERT zsd_tb_json_stat FROM ls_tb_json_sta.

          WHEN 1.
            upd_status_oe(
                EXPORTING
                  iv_status = 'S'
                CHANGING
                  is_docdig = es_docdig ).

            ls_tb_json_sta = VALUE zsd_tb_json_stat(
                bukrs      = es_docdig-tplst
                tdocumento = es_docdig-tdocumento
                vbeln      = es_docdig-vbeln_oe
                ncontrol   = ls_json_sta-ncontrol
                url        = ls_json_sta-url
                fechareci  = sy-datum
                usuario    = sy-uname ).

            SELECT SINGLE vbeln
              FROM zsd_tb_json_stat
              WHERE bukrs = @es_docdig-tplst AND
                    vbeln = @es_docdig-vbeln_oe
               INTO @DATA(lv_vbeln).

            IF lv_vbeln EQ 0.

              INSERT zsd_tb_json_stat FROM ls_tb_json_sta.

              ls_log-pagina = es_docdig-pag.
            ELSE.
              UPDATE zsd_tb_json_stat
                 SET url = ls_json_sta-url
               WHERE bukrs = es_docdig-tplst AND
                     vbeln = es_docdig-vbeln_oe.

            ENDIF.

          WHEN OTHERS.
            ls_log = VALUE zsd_tb_oe_log( sociedad   = iv_tplst
                                          tdocumento = ls_json_sta-tdocumento
                                          ndocumento = ls_json_sta-ndocumento
                                          fecha      = ls_json_sta-fecha
                                          mensaje    = ls_json_sta-mensaje
                                          ncontrol   = ls_json_sta-ncontrol
                                          status     = ls_json_sta-status
                                          url        = ls_json_sta-url
                                          uname      = sy-uname
                                          erdat      = sy-datum
                                          erzet      = sy-uzeit ).
            set_log( is_oe_log = ls_log ).

            CONCATENATE ls_json_sta-tdocumento ls_json_sta-ndocumento
                   INTO mv_men_1 SEPARATED BY space.

            ls_message = VALUE symsg( msgty = gc_status_e
                                msgid = '05'
                                msgno = '005'
                                msgv1 = mv_men_1
                                msgv2 = ls_json_sta-mensaje ).
            APPEND ls_message TO lt_message.

            set_message( lt_message ).
            cs_log = ls_log.
            EXIT.
        ENDCASE.
      WHEN 'GC' OR 'GD'.

        es_gc-aenam = sy-uname.
        es_gc-aedat = sy-datum.
        es_gc-aezet = sy-uzeit.

        CASE ls_json_sta-status.
          WHEN 0 OR 1.

            es_gc-url = ls_json_sta-url.

            upd_status_gc(
              EXPORTING
                iv_status = 'S'
              CHANGING
                is_docdig = es_gc ).

          WHEN OTHERS.
            ls_log = VALUE zsd_tb_oe_log( sociedad   = iv_tplst
                                          tdocumento = ls_json_sta-tdocumento
                                          ndocumento = ls_json_sta-ndocumento
                                          fecha      = ls_json_sta-fecha
                                          mensaje    = ls_json_sta-mensaje
                                          ncontrol   = ls_json_sta-ncontrol
                                          status     = ls_json_sta-status
                                          url        = ls_json_sta-url
                                          uname      = sy-uname
                                          erdat      = sy-datum
                                          erzet      = sy-uzeit ).

            set_log( is_oe_log = ls_log ).

            CONCATENATE ls_json_sta-tdocumento ls_json_sta-ndocumento
                   INTO mv_men_1 SEPARATED BY space.

            ls_message = VALUE symsg( msgty = gc_status_e
                                msgid = '05'
                                msgno = '005'
                                msgv1 = mv_men_1
                                msgv2 = ls_json_sta-mensaje ).
            APPEND ls_message TO lt_message.

            set_message( lt_message ).
            cs_log = ls_log.
            EXIT.
        ENDCASE.
    ENDCASE.

    ls_log-sociedad = iv_tplst.
    ls_log-ndocumento = ls_json_sta-ndocumento.
    ls_log-ncontrol = ls_json_sta-ncontrol.
    ls_log-status = ls_json_sta-status.
    ls_log-mensaje = ls_json_sta-mensaje.
    ls_log-url = ls_json_sta-url.
    ls_log-erzet = sy-uzeit.
    ls_log-fecha = sy-datum.

    set_log( is_oe_log = ls_log ).

*    ENDIF.

* Liberar el cliente HTTP
    me->close_http( lo_http_client ).

    CONCATENATE ls_json_sta-mensaje 'T. Doc.'
                ls_json_sta-tdocumento
           INTO mv_men_1 SEPARATED BY space.

    IF ls_json_sta-tdocumento EQ 'OE' OR
       ls_json_sta-tdocumento EQ 'LR'.
      CONCATENATE ls_json_sta-ndocumento 'N° Control'
                  ls_json_sta-ncontrol
             INTO mv_men_2 SEPARATED BY space.
    ELSE.
      CONCATENATE ls_json_sta-ndocumento ls_json_sta-ndocumento
             INTO mv_men_2 SEPARATED BY space .
    ENDIF.

    ls_message = VALUE symsg( msgty = 'S'
                              msgid = '01'
                              msgno = '001'
                              msgv1 = mv_men_1
                              msgv2 = mv_men_2 ).

    APPEND ls_message TO lt_message.

    set_message( lt_message  ).

    rv_return = abap_true.
  ENDMETHOD.

  METHOD get_datos_cabecera.
    DATA: lv_name  TYPE thead-tdname,
          lv_tknum TYPE tknum.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = iv_tknum
      IMPORTING
        output = lv_tknum.

    lv_name = lv_tknum.

*    SELECT SINGLE smtp_addr
*      INTO @DATA(lv_correo_transp)
*      FROM adr6
*     WHERE addrnumber EQ @es_item-adrnr AND
*           flgdefault EQ 'X'.

*    IF sy-subrc EQ 0.
*      es_item-correotransp = lv_correo_transp.
*    ENDIF.

    LOOP AT et_table ASSIGNING FIELD-SYMBOL(<lfs_cab>).
*      <lfs_cab>-orddev = is_dat_gc-ord_dev.
*      <lfs_cab>-ordequi = is_dat_gc-ord_equi.
*      <lfs_cab>-precintos = is_dat_gc-precintos.
*      <lfs_cab>-notcred = is_dat_gc-nota_cred.
      <lfs_cab>-despachador = is_dat_gc-despachador.
*      <lfs_cab>-correotransp = es_item-correotransp.

*** TEXTO: PARA BUSCAR EL CONDUCTOR
      me->get_texto(
         EXPORTING
           iv_id     = 'Z001'
           iv_object = 'VTTK'
           iv_name   = lv_name
         IMPORTING
           ev_name   = DATA(wa_line) ).

      <lfs_cab>-conductor = wa_line.

*      IF <lfs_cab>-conductor IS INITIAL.
*        ev_mensaje = 'Inegresar el conductor'.
*      ENDIF.

*** TEXTO PARA BUSCAR EL TELEFONO
      me->get_texto(
          EXPORTING
            iv_id     = 'Z002'
            iv_object = 'VTTK'
            iv_name   = lv_name
          IMPORTING
            ev_name   = wa_line ).

      <lfs_cab>-telefono = wa_line.

*      IF <lfs_cab>-telefono IS INITIAL.
*        ev_mensaje = 'Inegresar el teléfono'.
*      ENDIF.

*** TEXTO PARA SENALAR LAS PLACAS
      me->get_texto(
          EXPORTING
            iv_id     = 'Z004'
            iv_object = 'VTTK'
            iv_name   = lv_name
          IMPORTING
            ev_name   = wa_line ).

      <lfs_cab>-placa = wa_line.

*      IF <lfs_cab>-placa IS INITIAL.
*        ev_mensaje = 'Inegresar la placa del vehículo'.
*      ENDIF.

*** TEXTO: PARA BUSCAR LAS OBSERVACIONES
      me->get_texto(
          EXPORTING
            iv_id     = 'Z005'
            iv_object = 'VTTK'
            iv_name   = lv_name
          IMPORTING
            ev_name   = wa_line ).

      <lfs_cab>-observaciones = wa_line.

      IF iv_proccess NE 'GD'.
*** TEXTO PARA SENALAR EL PASE DE VIGILANCIA
        me->get_texto(
            EXPORTING
              iv_id     = 'Z003'
              iv_object = 'VTTK'
              iv_name   = lv_name
            IMPORTING
              ev_name   = wa_line ).

        <lfs_cab>-pasevigilancia = wa_line.

*        IF <lfs_cab>-pasevigilancia IS INITIAL.
*          ev_mensaje = 'Inegresar el pase de vigilancia'.
*        ENDIF.

*** TEXTO: Busca el Peso de la Romana
        me->get_texto(
            EXPORTING
              iv_id     = 'Z006'
              iv_object = 'VTTK'
              iv_name   = lv_name
            IMPORTING
              ev_name   = wa_line ).

        <lfs_cab>-pesoromana = wa_line.

*        IF <lfs_cab>-pesoromana IS INITIAL.
*          ev_mensaje = 'Inegresar el peso de la romana'.
*        ENDIF.

      ENDIF.

**** TEXTO: Busca correo de la unidad de transporte
*      me->get_texto(
*          EXPORTING
*            iv_id     = 'Z007'
*            iv_object = 'VTTK'
*            iv_name   = lv_name
*          IMPORTING
*            ev_name   = wa_line ).
*
*      <lfs_cab>-correo = wa_line.
*
*      es_item-correo = wa_line.

*** TEXTO: Busca la cedula del conductor
      me->get_texto(
          EXPORTING
            iv_id     = 'Z008'
            iv_object = 'VTTK'
            iv_name   = lv_name
          IMPORTING
            ev_name   = wa_line ).

      <lfs_cab>-ciconductor = wa_line.
      es_item-ciconductor = wa_line.
    ENDLOOP.

    IF ev_mensaje IS INITIAL.
      rv_return = abap_true.
    ENDIF.
  ENDMETHOD.

  METHOD get_texto.
    FREE lt_lines.
    CLEAR lt_lines.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        client          = sy-mandt
        id              = iv_id
        language        = lc_spras
        name            = iv_name
        object          = iv_object
      TABLES
        lines           = lt_lines
      EXCEPTIONS
        id              = 01
        language        = 02
        name            = 03
        not_found       = 04
        object          = 05
        reference_check = 06.

    READ TABLE lt_lines INTO DATA(wline) INDEX 1.

    MOVE wline-tdline TO ev_name.
  ENDMETHOD.

  METHOD get_destino.
    DATA: lt_table TYPE STANDARD TABLE OF zv_cds_gcp.

    CLEAR: technical_message,
           me->ls_message, me->ls_return, me->lt_return.

    lt_table[] = it_table[].

    SORT lt_table BY distancia DESCENDING.

    READ TABLE lt_table INDEX 1 INTO DATA(wa_item).

* Verificar
    READ TABLE et_table
         ASSIGNING FIELD-SYMBOL(<lfs_head>)
         WITH KEY nrotrans = wa_item-nrotrans.

    IF sy-subrc EQ 0.
      <lfs_head>-ciudad = wa_item-city1.
      <lfs_head>-estado = wa_item-estado.

      rv_return = abap_true.
    ELSE.
      me->ls_message = VALUE symsg( msgty = 'W'
                                    msgid = '03'
                                    msgno = '003'
                                    msgv1 = 'Falta asignar Destino del transporte' ).

      APPEND me->ls_message TO me->lt_message.

      me->set_message( me->lt_message ).
    ENDIF.
  ENDMETHOD.

  METHOD create_json_gc.
*    CONSTANTS: c_object_start TYPE c VALUE '{',
*               c_object_end   TYPE c VALUE '}'.

*    CONSTANTS: lc_asunto TYPE so_obj_des VALUE 'Error de comunicación con servicio SL'.

    DATA(lo_doc_digital) = NEW zcl_sd_desp_digital( ).

    DATA: ls_tothead TYPE ty_tothead,
          ls_totitem TYPE ty_totitem.

    CLEAR technical_message.

    DATA: lv_men_1    TYPE symsgv,
          lv_men_2    TYPE symsgv,
          lv_pag(2)   TYPE c,
          lv_hora     TYPE tims,
          lv_am_pm(2) TYPE c.

    DATA: ls_cab TYPE zsd_st_gd_json, "zsd_st_dd_json,
          ls_det TYPE zsd_st_desp_detalle, "zsd_st_dd_detalle.
          ls_url TYPE zsd_st_url.

    DATA: lv_json   TYPE string,
          ls_json   TYPE zsd_st_json_status,
          ti_report TYPE TABLE OF zsd_st_gd_json. " zsd_st_dd_json.

    DATA: it_inputparams TYPE tihttpnvp,
          ls_inputparams TYPE LINE OF tihttpnvp.

    DATA wa_duplica TYPE ty_gc_item.

    DATA ls_log TYPE zsd_tb_oe_log.

    wa_duplica[] = it_items[].

    DELETE ADJACENT DUPLICATES FROM wa_duplica COMPARING dircliente.

    DESCRIBE TABLE wa_duplica LINES DATA(lv_repartos).

    REFRESH: ti_report.

    LOOP AT it_head INTO DATA(ls_head).
*      WHERE frkrl EQ abap_true. También verificar
      CLEAR ls_cab.

      SELECT SINGLE *
        FROM zsd_tb_gck
       WHERE tplst EQ @ls_head-tplst AND
             tknum EQ @ls_head-nrotrans
        INTO @DATA(ls_gck).

      IF sy-subrc NE 0.
        ls_gck = VALUE zsd_tb_gck( mandt      = sy-mandt
                                   tplst      = ls_head-tplst
                                   tdocumento = iv_document
                                   tknum      = ls_head-nrotrans
                                   estado     = 'C'
                                   ernam      = sy-uname
                                   erdat      = sy-datum
                                   erzet      = sy-uzeit ).

        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING
            input  = ls_gck-tknum
          IMPORTING
            output = ls_gck-tknum.

        INSERT INTO zsd_tb_gck VALUES ls_gck.

        IF sy-subrc EQ 0.
          lo_doc_digital->commit_work( ).
        ENDIF.

      ELSE.
        IF ls_gck-estado EQ 'S'.

          CONCATENATE 'Nro Transporte:'
                       ls_gck-tknum
*                       'Pag:'
*                       ls_gck-pagina
                 INTO lv_men_1 SEPARATED BY space.

          CONCATENATE 'Fue generada el despacho de Retiro por Planta'
                      ls_gck-tknum
                 INTO lv_men_2 SEPARATED BY space.

          ls_message = VALUE symsg( msgty = 'W'
                                    msgid = '04'
                                    msgno = '004'
                                    msgv1 = lv_men_1
                                    msgv2 = lv_men_2 ).

          APPEND ls_message TO lt_message.

*          me->set_message( lt_message ).
          lo_doc_digital->set_message( lt_message ).

          EXIT.
        ENDIF.

      ENDIF.

* Totales del Head

*      ls_tothead = REDUCE ty_tothead( INIT tot TYPE ty_tothead
*                                      FOR wa IN it_head
*                                          WHERE ( pag EQ ls_head-pag )
*                                          NEXT tot-paletas = tot-paletas + wa-paleta
*                                               tot-palconsig = tot-palconsig + wa-kulab ).

* Totales Items
      ls_totitem = REDUCE ty_totitem( INIT tot_i TYPE ty_totitem
                                        FOR wa_i IN it_items
                                          WHERE ( pag EQ ls_head-pag )
                                            NEXT tot_i-totkcarga = tot_i-totkcarga + wa_i-kgcarga
                                                 tot_i-totgalones = tot_i-totgalones + wa_i-galones
                                                 tot_i-totbultos = tot_i-totbultos + wa_i-bultos ).

*      IF ls_totitem-totkcarga GT '99999.99'.
*
*        lv_men_1 = |Nro Transporte: { ls_gck-tknum } supera el peso|.
*        lv_men_2 = |permitido para el vehículo: { ls_totitem-totkcarga }|.
*
*        ls_message = VALUE symsg( msgty = 'W'
*                                  msgid = '04'
*                                  msgno = '004'
*                                  msgv1 = lv_men_1
*                                  msgv2 = lv_men_2 ).
*
*        APPEND ls_message TO lt_message.
*
*        lo_doc_digital->set_message( lt_message ).
*
*      ENDIF.

*      IF iv_document = 'GD'.
*        DATA(lv_document) = 'GC'.
*      ELSE.
*        lv_document = iv_document.
*      ENDIF.

      ls_cab = VALUE zsd_st_gd_json(
         tdocumento     = iv_document
         femision       = ls_gck-erdat
         hemision       = sy-uzeit
         nrotransporte  = ls_head-nrotrans
         puesto         = ls_head-puesto
         conductor      = ls_head-conductor
         telefono       = ls_head-telefono
*         correo         = ls_head-correo
         estado         = ls_head-estado
         ciudad         = ls_head-ciudad
         pasevigila     = ls_head-pasevigilancia
         transporte     = ls_head-puesto "transp
         tipovehiculo   =  COND string( WHEN iv_document EQ 'RXP'
                                        THEN space
                                        ELSE ls_head-tipveh )
         totalkilo      = ls_totitem-totkcarga
         totalgalones   = ls_totitem-totgalones
*         hojaservic     = ls_head-nrohoja
         nroplaca       = ls_head-placa
*         doccompra      = ls_head-acepservicio
         totalbulto     = ls_totitem-totbultos
         cantidadrepart = lv_repartos
         observaciones  = ls_head-observaciones
         ordevolucion   = ls_head-orddev
         ordequipo      = ls_head-ordequi
*         paletaentreg   = ls_tothead-paletas
         nroprecinto    = ls_head-precintos
         pesoromana     = ls_head-pesoromana
*         nc             = ls_head-notcred
         superdespacho  = ls_head-supervisor
         preparador     = ls_head-preparador
         paletaconsig   = ls_tothead-palconsig
         despachador    = ls_head-despachador
         riftransporte  = ls_head-rif_rxp
         ciconductor    = ls_head-rif_rxp ).

      ls_cab-dias_ruta = ls_head-gesztd / 240000.

*      WRITE ls_head-pag TO lv_pag.
*
*      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
*        EXPORTING
*          input  = lv_pag   " C field
*        IMPORTING
*          output = lv_pag.   " Internal display of INPUT, any category

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = ls_head-nrotrans
        IMPORTING
          output = ls_cab-nrotransporte.

*      CONCATENATE ls_head-nrotrans '-' lv_pag
*             INTO ls_cab-nrotransporte.

      CONDENSE: ls_cab-nrotransporte NO-GAPS,
                ls_cab-totalkilo NO-GAPS,
                ls_cab-totalgalones NO-GAPS,
                ls_cab-paletaentreg NO-GAPS,
                ls_cab-paletaconsig NO-GAPS.

      IF sy-sysid NE gc_sistema.
        DATA(lt_correo) = VALUE zsd_tt_det_correo(
*               ( correo = ls_head-correo )
*               ( correo = ls_head-correotransp )
               ( correo = gc_dest_dist ) ).

      ELSE.
        CLEAR: ls_cab-correo, lt_correo.
        REFRESH lt_correo.

        lt_correo = VALUE zsd_tt_det_correo(
               ( correo = 'carlos_falcon@corimon.com' )
               ( correo = 'pedro_marquez@corimon.com' )
               ( correo = 'jonathan_gonzalez@corimon.com' )
               ( correo = 'angee_mendoza@corimon.com' )
               ( correo = 'mtanzella@innovosite.com' )
               ( correo = 'yflores@innovosite.com' ) ).

      ENDIF.

      MOVE lt_correo[] TO ls_cab-correo[].

      ls_cab-banners = lo_doc_digital->get_banner( iv_tpls  = ls_head-tplst
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
          APPEND VALUE #( vbeln     = ls_item-nrodocumento
                         rifdestino = ls_item-rifdestino
                         nomdestino = ls_item-nomcliente )
                TO et_destino.
        ENDIF.

        ls_det = VALUE zsd_st_desp_detalle( cliente      = ls_item-nomcliente
                                            nrodocumento = ls_item-nrodocumento
                                            bultos       = ls_item-bultos
                                            ciudad       = ls_item-city1 ).

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

        ENDIF.

        ls_det-distribuidor = COND string( WHEN ls_item-lfart EQ 'NL' THEN 'SI' ELSE 'NO' ).

        REPLACE ALL OCCURRENCES OF '"' IN ls_det-ciudad WITH ' '.

        APPEND ls_det TO ls_cab-detalles[].

      ENDLOOP.

      wa_duplica[] = it_items[].

      DELETE ADJACENT DUPLICATES FROM wa_duplica COMPARING nrotrans.

      LOOP AT wa_duplica INTO ls_item.

        SELECT SINGLE *
          FROM zsd_tb_gcp
         WHERE tknum_c EQ @ls_head-nrotrans AND
               tknum   EQ @ls_item-nrotrans AND
               pagina  EQ @ls_head-pag
          INTO @DATA(ls_gcp).

        IF sy-subrc NE 0.
          ls_gcp = VALUE zsd_tb_gcp( mandt   = sy-mandt
                                     tknum_c = ls_head-nrotrans
                                     tknum   = ls_item-nrotrans
                                     pagina  = ls_head-pag
                                     estado  = 'C'
                                     ernam   = sy-uname
                                     erdat   = ls_gck-erdat
                                     erzet   = sy-uzeit ).

          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = ls_gcp-tknum_c
            IMPORTING
              output = ls_gcp-tknum_c.

          INSERT INTO zsd_tb_gcp VALUES ls_gcp.

        ELSE.
          IF ls_gcp-estado EQ 'S'.

            lv_men_1 = |Nro Transporte: { ls_item-nrotrans }|.

            lv_men_2 = |Fue generada en la Guia de Despacho digital { ls_gck-tknum }|.

            ls_message = VALUE symsg( msgty = 'W'
                                      msgid = '04'
                                      msgno = '004'
                                      msgv1 = lv_men_1
                                      msgv2 = lv_men_2 ).

            APPEND ls_message TO lt_message.

            lo_doc_digital->set_message( lt_message ).

          ENDIF.

        ENDIF.

      ENDLOOP.

      IF ls_gcp-estado NE 'S'.

        lo_doc_digital->upd_status_gc(
          EXPORTING
            iv_status = 'G'
          CHANGING
            is_docdig = ls_gcp ).

        APPEND ls_cab TO ti_report.

        CLEAR lv_json.

*        zcl_json_utility=>convert_stuct_to_json(
*          EXPORTING
*             im_s_data = ls_cab
*             im_v_case = zcl_json_utility=>co_ftype_lowercase "co_ftype_camelcase
*          RECEIVING
*             rt_v_json = lv_json ).

*        IF sy-uname EQ '700-009' AND mv.
        IF mv_view EQ abap_true.
          cl_demo_output=>display( lv_json ).

          IF gc_sistema NE 'QR3'.
            lv_men_1 = |Guía de carga No procesada|.

            ls_message = VALUE symsg( msgty = 'W'
                                      msgid = '04'
                                      msgno = '004'
                                      msgv1 = lv_men_1 ).

            APPEND ls_message TO lt_message.

            lo_doc_digital->set_message( lt_message ).

          ENDIF.


        ENDIF.

*        IF lo_doc_digital->get_serv_dana(
*           EXPORTING
*             iv_process = iv_document
*             iv_json    = lv_json
*             iv_tplst   = ls_gck-tplst
*           CHANGING
*             es_gc      = ls_gcp
*             cs_log     = ls_log ) EQ abap_false.
*
*          TRY.
*              DATA(lo_msg) = NEW zcl_email_fd( i_asunto = lc_asunto
*                                               i_oe_log = ls_log ).
*            CATCH cx_abap_invalid_value.
*          ENDTRY.
*
*          IF lo_msg IS BOUND.
*            MESSAGE i208(00) WITH 'Se envío notificación.'.
*          ELSE.
*            MESSAGE i208(00) WITH 'No se pudo enviar la notificación.'.
*          ENDIF.
*
*        ELSE.

        CHECK lt_message[] IS NOT INITIAL.

*        ev_json = lv_json.

        lo_doc_digital->upd_status_gc(
          EXPORTING
            iv_status = 'S'
          CHANGING
            is_docdig = ls_gcp ).
*        ENDIF.
      ENDIF.

    ENDLOOP.

    zcl_json_utility=>convert_itab_to_json(
      EXPORTING
        im_t_table = ti_report
        im_v_case  = zcl_json_utility=>co_ftype_lowercase
      RECEIVING
        rt_v_json  = lv_json ).

    ev_json = lv_json.

    IF sy-subrc EQ 0. "DR3K981184 cfalcon SD:I578:12022026 - Correccion
      ls_gck-estado = 'S'.
      ls_gck-aedat = sy-datum.
      ls_gck-aezet = sy-uzeit.

      MODIFY zsd_tb_gck FROM ls_gck.
      rv_return = abap_true.
    ELSE.
      technical_message = 'No se genero la estructura JSON'.
    ENDIF.

  ENDMETHOD.

  METHOD get_tot_enc.

*    DATA(ls_tot) = REDUCE ty_tothead( INIT suma TYPE ty_tothead
*                                        FOR wa IN it_table
*                                          NEXT suma-paletas = suma-paletas + wa-paleta
*                                               suma-kilos   = suma-kilos + wa-kulab ).

*    ev_totkilo = ls_tot-kilos.
*    ev_paletas = ls_tot-paletas.

  ENDMETHOD.

  METHOD check_transporte.
    DATA lv_lines_count TYPE i.

    CLEAR technical_message.
    CLEAR: me->ls_message, me->ls_return, me->lt_return,
           lv_lines_count.

* No tiene transporte
*    LOOP AT it_table INTO DATA(lv_item)
*       WHERE frkrl EQ abap_true.
*      lv_lines_count = lv_lines_count + 1.
*    ENDLOOP.

    CASE lv_lines_count.
      WHEN 0.
        me->ls_message = VALUE symsg( msgty = 'W'
                                      msgid = '04'
                                      msgno = '004'
                                      msgv1 = 'Falta asignar el transportista' ).
      WHEN 1.
        rv_return = abap_true.
      WHEN OTHERS.
        me->ls_message = VALUE symsg( msgty = 'W'
                                            msgid = '05'
                                            msgno = '005'
                                            msgv1 = 'Hay más de un transportista asignado' ).
    ENDCASE.

    APPEND me->ls_message TO me->lt_message.

    me->set_message( me->lt_message ).

  ENDMETHOD.

  METHOD check_desp.
    DATA: lt_gc        TYPE STANDARD TABLE OF zview_gc,
          ls_gc        TYPE zview_gc,
          lv_fecha(10) TYPE c.

    CLEAR technical_message.
    CLEAR: me->ls_message, me->ls_return, me->lt_return,
           mv_men_1, mv_men_2.

    SELECT SINGLE *
      FROM zview_gc( p_tplst = @iv_tplst )
      INTO @ls_gc
      WHERE nrotransp_k EQ @iv_tknum.
*      WHERE nrotransp_k IN @it_tknum.

    IF sy-subrc EQ 0.

      IF ls_gc-estado_k = 'S'.
        CONCATENATE 'El transporte N°:' ls_gc-nrotransp_k
               INTO mv_men_1 SEPARATED BY space.

        WRITE ls_gc-fechaenvio TO lv_fecha DD/MM/YYYY.
        REPLACE ALL OCCURRENCES OF '.' IN lv_fecha WITH '/'.

        CONCATENATE ', fue generado con fecha del' lv_fecha
               INTO mv_men_2 SEPARATED BY space .

        me->ls_message = VALUE symsg( msgty = 'W'
                                      msgid = '07'
                                      msgno = '007'
                                      msgv1 = mv_men_1
                                      msgv2 = mv_men_2 ).

        APPEND me->ls_message TO me->lt_message.

        me->set_message( me->lt_message ).
        RETURN.
      ENDIF.
    ENDIF.

*    SELECT *
*      FROM zview_gc( p_tplst = @iv_tplst )
*      INTO TABLE @lt_gc
*      WHERE nrotransp EQ @iv_tknum.

*    LOOP AT lt_gc INTO ls_gc.
*    IF ls_gc-nrotransp_k NE ls_gc-nrotransp.
*
*      IF ls_gc-estado_k = 'S'.
*        CONCATENATE 'Transp. N°:' ls_gc-nrotransp
*                    'fue enviado en el Tranp.'
*               INTO mv_men_1 SEPARATED BY space.
*
*        WRITE ls_gc-fechaenvio TO lv_fecha DD/MM/YYYY.
*        REPLACE ALL OCCURRENCES OF '.' IN lv_fecha WITH '/'.
*
*        CONCATENATE ls_gc-nrotransp_k 'el' lv_fecha
*               INTO mv_men_2 SEPARATED BY space .
*
*        me->ls_message = VALUE symsg( msgty = 'W'
*                                      msgid = '07'
*                                      msgno = '007'
*                                      msgv1 = mv_men_1
*                                      msgv2 = mv_men_2 ).
*
*        APPEND me->ls_message TO me->lt_message.
*
*        me->set_message( me->lt_message ).
**        RETURN.
*      ENDIF.
*    ENDIF.
*
*    ENDLOOP.

    IF lt_message[] IS INITIAL.
      rv_return = abap_true.
    ELSE.
      RETURN.
    ENDIF.

  ENDMETHOD.

  METHOD get_transp_oe.
    DATA: lt_head   TYPE STANDARD TABLE OF zview_entrega_oe,
          ls_head   TYPE zview_entrega_oe,
          lv_return TYPE abap_bool,
          lv_name   TYPE thead-tdname,
*          lv_lifnr         TYPE lifnr,
          lv_men_1  TYPE symsgv,
          lv_men_2  TYPE symsgv,
          lv_error  TYPE abap_bool,
          lv_msgv1  TYPE symsgv.
*          lv_correodestino TYPE ad_smtpadr.gv_adrnr

    DATA lt_entrega TYPE TABLE OF ty_nroentrega.

    CLEAR: technical_message, me->ls_message, lv_msgv1.

    lv_error = abap_false.

* Ini 14.11.2025  58280 DR3K980446  FD Devolución de productos
    CASE iv_orddev.
      WHEN 'LR'.
        SELECT DISTINCT *
          FROM zview_entrega_dev( p_tplst = @iv_tplst )
          INTO TABLE @lt_head
         WHERE nrotransporte IN @it_tknum.
      WHEN OTHERS.
        SELECT DISTINCT *
          FROM zview_entrega_oe( p_tplst = @iv_tplst )
          INTO TABLE @lt_head
         WHERE nrotransporte IN @it_tknum AND
               lfart IN @lt_lfart.
    ENDCASE.
* Fin 14.11.2025  58280 DR3K980446  FD Devolución de productos

    SORT lt_head BY nroentrega ASCENDING.

    DELETE ADJACENT DUPLICATES FROM lt_head
          COMPARING nroentrega.

    IF NOT lt_head[] IS INITIAL.

      lt_entrega = VALUE #( FOR item IN lt_head
                              ( sign = 'I'
                                option = 'EQ'
                                low = item-nroentrega ) ).

      DATA(oc_descli) = NEW lcl_doc_dig( i_vbeln = lt_entrega ).

      LOOP AT lt_head ASSIGNING FIELD-SYMBOL(<lfs_head>).

        <lfs_head>-nrotranori = <lfs_head>-nrotransporte.

        IF iv_orddev NE 'LR'.
          IF <lfs_head>-isimprimir EQ abap_false.
            CONCATENATE 'La entrega' <lfs_head>-nroentrega
                   INTO lv_msgv1 SEPARATED BY space.

            ls_message = VALUE symsg( msgty = 'W'
                                      msgid = '02'
                                      msgno = '002'
                                      msgv1 = lv_msgv1
                                      msgv2 = 'no está concluida' ).

            APPEND ls_message TO lt_message.

            me->set_message( lt_message ).
            EXIT.
          ENDIF.
        ENDIF.

        SELECT SINGLE nametrans
          FROM zview_transporte
         WHERE lifnr EQ @<lfs_head>-tdlnr
          INTO @<lfs_head>-transporte.

        DATA(ls_adrnr) = oc_descli->destino_oe[ vbeln = <lfs_head>-nroentrega ].

        SELECT DISTINCT *
          FROM zview_inf_client
          INTO TABLE @DATA(lt_destino)
        WHERE adrnr EQ @ls_adrnr-adrnr  AND
                 comm_type EQ 'INT' AND
                 remark = 'FD'.

        READ TABLE lt_destino INTO DATA(ls_destino) INDEX 1.

        IF sy-subrc NE 0.
          lv_error = abap_true.

          CONCATENATE 'Nro Trans:'
                       <lfs_head>-nrotransporte
                       'en la Entrega:'
                       <lfs_head>-nroentrega
                 INTO lv_men_1 SEPARATED BY space.

          CONCATENATE ', falta información del cliente'
                       ls_adrnr-kunnr
                 INTO lv_men_2 SEPARATED BY space.

          ls_message = VALUE symsg( msgty = 'W'
                                    msgid = '01'
                                    msgno = '001'
                                    msgv1 = lv_men_1
                                    msgv2 = lv_men_2 ).

          APPEND ls_message TO lt_message.

          me->set_message( lt_message ).
        ENDIF.

        MOVE ls_destino-correodestino TO <lfs_head>-correodestino.

        IF <lfs_head>-correodestino IS INITIAL.
          CONCATENATE 'para la OE:'
                      <lfs_head>-nroentrega
                 INTO mv_men_2.

          me->ls_message = VALUE symsg( msgty = 'W'
                                        msgid = '11'
                                        msgno = '011'
                                        msgv1 = 'Verifique el correo del destinario y/o pagador,'
                                        msgv2 = mv_men_2 ).

          APPEND me->ls_message TO me->lt_message.

          me->set_message( me->lt_message ).
        ENDIF.

        CONCATENATE ls_destino-dirclient1 ls_destino-dirclient2
                    ls_destino-cityclient2 ls_destino-paisclient
                    ls_destino-correodestino
             INTO <lfs_head>-direceptor
        SEPARATED BY space.

        MOVE <lfs_head>-nrotransporte TO lv_name.

*** Texto Placa de Transporte
        me->get_texto(
            EXPORTING
              iv_id     = 'Z004'
              iv_object = 'VTTK'
              iv_name   = lv_name
            IMPORTING
              ev_name   = DATA(wa_line) ).

        <lfs_head>-nroplaca = wa_line.

        MOVE <lfs_head>-nropedido TO lv_name.

*** TEXTO: PARA BUSCAR LAS OBSERVACIONES en el pedido
        me->get_texto(
            EXPORTING
              iv_id     = '0001'
              iv_object = 'VBBK'
              iv_name   = lv_name
            IMPORTING
              ev_name   = wa_line ).

        <lfs_head>-observaciones = wa_line.

      ENDLOOP.

*      CHECK ls_message IS INITIAL.

      IF me->get_oe_items(
       EXPORTING
         it_table  = lt_head
       IMPORTING
         et_table  = et_items ) EQ abap_false.
      ENDIF.

      IF lt_message[] IS INITIAL.
        rv_return = abap_true.
      ENDIF.

    ENDIF.

    IF lt_head[] IS INITIAL.
      ls_message = VALUE symsg( msgty = 'W'
                                msgid = '01'
                                msgno = '001'
                                msgv1 = 'Verifique Los Transportes tengan'
                                msgv2 = 'Ordenes de Entregas' ).

      APPEND ls_message TO lt_message.

      me->set_message( lt_message ).
    ENDIF.

    et_head[] = lt_head[].
  ENDMETHOD.

  METHOD get_oe_items.
    DATA: lt_items TYPE STANDARD TABLE OF zview_entp_oe,
          ls_item  TYPE zview_entp_oe,
          lt_df    TYPE STANDARD TABLE OF zview_doc_flujo.

    DATA: ltr_nroentrega TYPE TABLE OF ty_nroentrega,
          lsr_nroentrega TYPE ty_nroentrega.

    CLEAR: technical_message, me->ls_message, mv_men_1, mv_men_2.

    CLEAR: ltr_nroentrega[].
    REFRESH ltr_nroentrega[].

    LOOP AT it_table INTO DATA(ls_head).
      CLEAR lsr_nroentrega.

      lsr_nroentrega-sign = 'I'.
      lsr_nroentrega-option = 'EQ'.
      lsr_nroentrega-low = ls_head-nroentrega.

      APPEND lsr_nroentrega TO ltr_nroentrega.
    ENDLOOP.

    SELECT *
      FROM zview_entp_oe
      INTO TABLE @DATA(lt_trans_items)
     WHERE nroentrega IN @ltr_nroentrega.

    IF sy-subrc EQ 0.

      LOOP AT lt_trans_items INTO DATA(ls_oe_items).

        IF ls_oe_items-preciounitario EQ 0.
          CONCATENATE 'En la Entrega' ls_oe_items-nroentrega
                 INTO mv_men_1 SEPARATED BY space.

          CONCATENATE 'el material' ls_oe_items-matnr 'no tiene precio'
                 INTO mv_men_2 SEPARATED BY space.

          ls_message = VALUE symsg( msgty = 'W'
                                    msgid = '02'
                                    msgno = '002'
                                    msgv1 = mv_men_1
                                    msgv2 = mv_men_2 ).

          APPEND ls_message TO lt_message.

          me->set_message( lt_message ).
          RETURN.

        ENDIF.

      ENDLOOP.

      et_table[] = lt_trans_items[].

      IF lt_message[] IS INITIAL.
        rv_return = abap_true.
      ENDIF.

    ENDIF.

  ENDMETHOD.

  METHOD create_json_oe.
    CONSTANTS: c_object_start TYPE c VALUE '{',
               c_object_end   TYPE c VALUE '}'.

    CONSTANTS: lc_asunto TYPE so_obj_des VALUE 'Error de comunicación con servicio SL'.

    DATA: ls_user TYPE zv_user_function.

    DATA(lo_doc_digital) = NEW zcl_sd_desp_digital( ).

    CLEAR: technical_message, ls_message.

    DATA: ls_cab TYPE zsd_st_json,
          ls_det TYPE zsd_detalles.

    DATA: lv_docvir(10) TYPE c,
          lv_error      TYPE abap_bool,
          lv_json       TYPE string,
          lv_pag(2)     TYPE c,
          lv_hora       TYPE  tims,
          lv_fecpro     TYPE datum,
          lv_banners    TYPE zbanners,
          ti_report     TYPE TABLE OF zsd_st_json.

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

    LOOP AT it_head INTO DATA(ls_head)
      WHERE status NE lv_status. " 'S'.

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

      IF ls_docdig-estado EQ 'S'.

        CONCATENATE 'Nro entrega:'
                     ls_docdig-vbeln
                     'Pag:'
                     ls_docdig-pag
               INTO lv_men_1 SEPARATED BY space.

        CONCATENATE 'Fue generada en la entrega digital'
                    ls_docdig-vbeln_oe
               INTO lv_men_2 SEPARATED BY space.

        ls_message = VALUE symsg( msgty = 'W'
                                  msgid = '04'
                                  msgno = '004'
                                  msgv1 = lv_men_1
                                  msgv2 = lv_men_2 ).

        APPEND ls_message TO lt_message.

        lo_doc_digital->set_message( lt_message ).
      ELSE.

        IF sy-subrc NE 0.
          CALL FUNCTION 'NUMBER_GET_NEXT'
            EXPORTING
              nr_range_nr             = '00'
              object                  = 'ZSD_FD_OE'
            IMPORTING
              number                  = lv_docvir
            EXCEPTIONS
              interval_not_found      = 1
              number_range_not_intern = 2
              object_not_found        = 3
              quantity_is_0           = 4
              quantity_is_not_1       = 5
              interval_overflow       = 6
              buffer_overflow         = 7
              OTHERS                  = 8.

          IF sy-subrc NE 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

            ls_message = VALUE symsg( msgty = 'W'
                                      msgid = '03'
                                      msgno = '003'
                                      msgv1 = 'No se puede crear el Nro. Ord. de entrega' ).

            APPEND ls_message TO lt_message.

            lo_doc_digital->set_message( lt_message ).

            lv_error = abap_true.
            EXIT.
          ENDIF.

          IF ls_docdig IS INITIAL.
            ls_docdig = VALUE zsd_likp_oe( mandt      = sy-mandt
                                           tplst      = ls_head-orgvta
                                           vbeln      = ls_head-nroentrega
                                           pag        = ls_head-pag
                                           tdocumento = iv_document
                                           vbeln_oe   = lv_docvir
                                           estado     = 'C'
                                           uname      = sy-uname
                                           erdat      = iv_fecdoc
                                           erzet      = sy-uzeit ).

            INSERT INTO zsd_likp_oe VALUES ls_docdig.

            lo_doc_digital->commit_work( ).
          ENDIF.

        ELSE.
          lv_docvir = ls_docdig-vbeln_oe.
        ENDIF.

        CLEAR ls_cab.

        ls_docdig-femision = iv_fecdoc.
        ls_docdig-hemision = sy-uzeit.

        IF iv_document EQ 'LR'.
          DATA(lv_document) = 'OE'.
        ELSE.
          lv_document = iv_document.
        ENDIF.

        ls_cab = VALUE zsd_st_json( tdocumento     = lv_document
                                    ndocumento     = lv_docvir
*                                    femision       = ls_docdig-erdat
*                                    hemision       = ls_docdig-erzet
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

        TRANSLATE ls_cab-paisciudad TO UPPER CASE.

        CONCATENATE ls_head-correodestino '/'
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

          CONCATENATE 'pedro_marquez@corimon.com' '/'
                      'carlos_falcon@corimon.com' '/'
                      'william_leon@corimon.com'
                 INTO ls_cab-correo.
        ENDIF.

        lo_doc_digital->set_char_esp(
          EXPORTING
            iv_string = ls_cab-codcliente
          IMPORTING
            ev_string = ls_cab-codcliente ).

        lo_doc_digital->set_char_esp(
          EXPORTING
            iv_string = ls_cab-plvehiculo
          IMPORTING
            ev_string = ls_cab-plvehiculo ).

        lo_doc_digital->set_char_esp(
          EXPORTING
            iv_string = ls_cab-direceptor
          IMPORTING
            ev_string = ls_cab-direceptor ).

        ls_cab-banners = lo_doc_digital->get_banner( iv_tpls  = ls_head-orgvta
                                                     iv_fecha = ls_docdig-erdat ).
        LOOP AT it_items INTO DATA(ls_item)
          WHERE nroentrega EQ ls_head-nroentrega AND
                pag = ls_head-pag.
          CLEAR ls_det.

          ls_det = VALUE zsd_detalles( codmaterial    = ls_item-matnr
                                       nrolote        = ls_item-nrolote
                                       prodescripcion = ls_item-desmaterial
                                       unimedida      = ls_item-unidmed
                                       preunitario    = ls_item-preciounitario ).

          ls_det-cantidad = round( val = ( ls_item-cantidad ) dec = 0  ).
          ls_det-galones  = round( val = ( ls_item-galones ) dec = 2  ).

          lv_totkilos = lv_totkilos + ls_item-kilos.
          lv_totgalones = lv_totgalones + ls_item-galones.
          lv_totgal = lv_totgal + ls_item-galones.
          lv_totbultos = lv_totbultos + ls_item-cantidad.
          lv_totimporte = lv_totimporte + ( ls_item-galones * ls_item-preciounitario ).
          lv_totimport = lv_totimport + ls_item-netwr.

          TRANSLATE ls_det-unimedida TO UPPER CASE.

          WRITE: ls_det-cantidad TO ls_det-cantidad NO-GROUPING DECIMALS 2 NO-GAP,
                 ls_det-preunitario TO ls_det-preunitario NO-GROUPING DECIMALS 2 NO-GAP,
                 ls_det-galones TO ls_det-galones NO-GROUPING DECIMALS 2 NO-GAP.

          CONDENSE: ls_det-cantidad NO-GAPS,
                    ls_det-preunitario NO-GAPS,
                    ls_det-galones NO-GAPS.

          APPEND ls_det TO ls_cab-detalles[].

        ENDLOOP.

        lv_totgalones = round( val = ( lv_totgal ) dec = 2  ).

        ls_cab-oepesotot = lv_totkilos.
        ls_cab-oeimptot  = lv_totimporte.
        ls_cab-oecantot  = lv_totbultos.
        ls_cab-galones   = lv_totgalones.

        ls_docdig-bultos = lv_totbultos.

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

        IF sy-uname EQ '700-009' AND
            sy-sysid NE gc_sistema.
          cl_demo_output=>display( lv_json ).
          lv_men_1 = |OE No procesada|.

          ls_message = VALUE symsg( msgty = 'W'
                                    msgid = '04'
                                    msgno = '004'
                                    msgv1 = lv_men_1 ).

          APPEND ls_message TO lt_message.

          lo_doc_digital->set_message( lt_message ).
          RETURN.
        ENDIF.

        IF lv_json IS INITIAL.

          lo_doc_digital->upd_status_oe(
            EXPORTING
              iv_status = gc_status_e
            CHANGING
              is_docdig = ls_docdig ).

**** Falta agregar el mensaje de error
          RETURN.
        ENDIF.

*        IF lo_doc_digital->get_serv_dana(
*          EXPORTING
*            iv_process = iv_document
*            iv_json    = lv_json
*            iv_tplst   = ls_head-orgvta
*          CHANGING
*            es_docdig  = ls_docdig
*            cs_log = ls_log ) EQ abap_false.
*
*          lv_men_1 = | Error para enviar Orden de Entrega { ls_log-ndocumento }|.
*
*          ls_message = VALUE symsg( msgty = 'W'
*                                  msgid = '06'
*                                  msgno = '006'
*                                  msgv1 = lv_men_1
*                                  msgv2 = ls_log-mensaje ).
*
*          APPEND ls_message TO lt_message.
*
*          lo_doc_digital->set_message( lt_message ).
*
*          TRY.
*              DATA(lo_msg) = NEW zcl_email_fd( i_asunto = lc_asunto
*                                               i_oe_log = ls_log ).
*            CATCH cx_abap_invalid_value.
**              out->write( | Mesaje de la exception | ).
*          ENDTRY.
*
*          IF lo_msg IS BOUND.
*            MESSAGE i208(00) WITH 'Se envío notificación.'.
*          ELSE.
*            MESSAGE i208(00) WITH 'No se pudo enviar la notificación.'.
*          ENDIF.
*
*          RETURN.
*        ENDIF.
      ENDIF.

      CLEAR ls_docdig.
    ENDLOOP.

    IF sy-subrc EQ 0.
      ev_json = lv_json.
      rv_return = abap_true.
    ELSE.
      technical_message = 'No se genero la estructura JSON'.
    ENDIF.
  ENDMETHOD.

  METHOD send_oe.
    DATA: lt_head     TYPE STANDARD TABLE OF zview_entrega_oe,
          lt_items    TYPE STANDARD TABLE OF zview_entp_oe,
          lv_totlines TYPE i,
          lv_pag      TYPE i.

    READ TABLE it_head
          INTO DATA(ls_transp)
          WITH KEY indgastrans = abap_true.

    LOOP AT it_head INTO DATA(ls_head).
      lv_pag = 1.
      ls_head-pag = lv_pag.
      lv_totlines = 0.

      IF ls_head-indgastrans EQ abap_false.
        ls_head-transporte = ls_transp-transporte.
        ls_head-nroplaca = ls_transp-nroplaca.
      ENDIF.

      APPEND ls_head TO lt_head.

      LOOP AT it_items INTO DATA(ls_item)
        WHERE nroentrega EQ ls_head-nroentrega.

        SELECT SINGLE mseh3
          FROM t006b
          INTO @DATA(lv_mseh3)
         WHERE spras = 'S' AND
               msehi = @ls_item-unidmed.

        IF sy-subrc = 0.
          ls_item-unidmed = lv_mseh3.
        ENDIF.

        lv_totlines = lv_totlines + 1.

        IF lv_totlines GT 19.
          lv_pag = lv_pag + 1.
          lv_totlines = 1.
        ENDIF.

        ls_item-pag = lv_pag.
        APPEND ls_item TO lt_items.

        IF ls_head-pag NE lv_pag.
          ls_head-pag = lv_pag.

          IF ls_head-indgastrans EQ abap_false.
            ls_head-transporte = ls_transp-transporte.
            ls_head-nroplaca = ls_transp-nroplaca.
          ENDIF.

          APPEND ls_head TO lt_head.
        ENDIF.

      ENDLOOP.

    ENDLOOP.

    IF NOT lt_head[] IS INITIAL.
      rv_return = abap_true.

      et_head[] = lt_head[].
      et_items[] = lt_items[].
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

    ENDIF.

  ENDMETHOD.

  METHOD check_date.
    DATA: lv_fecini    TYPE sy-datum,
          lv_fecfin    TYPE sy-datum,
          lv_fecfinmes TYPE sy-datum,
          lv_fecpro    TYPE sy-datum,
          lv_finmes    TYPE abap_bool.

    CLEAR: technical_message, me->ls_message. ", lv_msgv1.

    SELECT SINGLE proc_finmes, fechafmes
      FROM zfi_act_web_aut
     WHERE bukrs EQ @iv_bukrs AND
           proc_finmes EQ 'X'
      INTO ( @lv_finmes, @lv_fecfinmes ).

    lv_fecfin = sy-datum.
    lv_fecini = lv_fecfin - 7.

    SELECT SINGLE *
      FROM vbrk
     WHERE bukrs = @iv_bukrs AND
           fkdat >= @lv_fecini AND fkdat <= @lv_fecfin AND
           stceg = ''
      INTO @DATA(wa_vbrk).

    IF sy-subrc EQ 0.
      IF NOT wa_vbrk-fkdat IS INITIAL AND
         NOT lv_fecfinmes IS INITIAL.
        IF wa_vbrk-fkdat NE lv_fecfinmes.
          ls_message = VALUE symsg( msgty = 'W'
                                    msgid = '01'
                                    msgno = '001'
                                    msgv1 = 'Hay documentos pendientes por imprimir'
                                    msgv2 = 'antes de la fecha fin de mes' ).

          APPEND ls_message TO lt_message.

          me->set_message( lt_message ).
          RETURN.
        ENDIF.
      ENDIF.

      IF wa_vbrk-fkdat LT sy-datum.
        ls_message = VALUE symsg( msgty = 'W'
                                  msgid = '01'
                                  msgno = '001'
                                  msgv1 = 'Hay documentos pendientes por imprimir'
                                  msgv2 = '(FC, NC, ND)' ).

        APPEND ls_message TO lt_message.

        me->set_message( lt_message ).
        RETURN.
      ENDIF.
    ENDIF.

    IF lv_finmes EQ abap_true.
      ev_fecpro = lv_fecfinmes.
    ELSE.
      ev_fecpro = sy-datum.
    ENDIF.

    rv_return = abap_true.
  ENDMETHOD.

  METHOD val_transp_oe.
    DATA: lv_lines_count TYPE i,
          lt_table       TYPE ty_transp_head. "TYPE STANDARD TABLE OFzview_entrega_oe

    CLEAR technical_message.
    CLEAR: me->ls_message, me->ls_return, me->lt_return,
           lv_lines_count.

    lt_table[] = it_table[].

    SORT lt_table BY nrotransporte nrotranori tdlnr indgastrans ASCENDING.

    DELETE ADJACENT DUPLICATES FROM lt_table
          COMPARING nrotransporte nrotranori tdlnr indgastrans.

    lv_lines_count = REDUCE i( INIT contar = 0
                               FOR wa IN lt_table
                                 WHERE ( indgastrans EQ abap_true )
                                  NEXT contar = contar + 1 ).

    CASE lv_lines_count.
      WHEN 0.
        me->ls_message = VALUE symsg( msgty = 'W'
                                      msgid = '04'
                                      msgno = '004'
                                      msgv1 = 'Falta asignar el transportista' ).
      WHEN 1.
        rv_return = abap_true.
      WHEN OTHERS.
        me->ls_message = VALUE symsg( msgty = 'W'
                                            msgid = '05'
                                            msgno = '005'
                                            msgv1 = 'Hay más de un transportista asignado' ).
    ENDCASE.

    IF lv_lines_count NE 1.
      APPEND me->ls_message TO me->lt_message.

      me->set_message( me->lt_message ).
    ENDIF.
  ENDMETHOD.

  METHOD check_pend_oe.
    DATA: lv_lines_count TYPE i.

    CLEAR technical_message.
    CLEAR: me->ls_message, me->ls_return, me->lt_return,
           lv_lines_count.

    DATA: ltr_nroentrega TYPE TABLE OF ty_nroentrega,
          lsr_nroentrega TYPE ty_nroentrega.

    CLEAR: ltr_nroentrega[].
    REFRESH ltr_nroentrega[].

    ltr_nroentrega = VALUE #( FOR ls_table IN it_table
                               ( sign   = 'I'
                                 option = 'EQ'
                                 low    = ls_table-nroentrega ) ).

    SELECT *
      FROM zsd_likp_oe
     WHERE estado <> 'S'
      INTO TABLE @DATA(lt_oe_p).

    IF sy-subrc EQ 0.

      SELECT *
        FROM zsd_likp_oe
       WHERE estado NE 'S' AND
             vbeln IN @ltr_nroentrega
        INTO TABLE @DATA(lt_oe).

    ENDIF.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD check_oe_gen.
    DATA: lt_head     TYPE STANDARD TABLE OF zview_entrega_oe,
          lt_items    TYPE STANDARD TABLE OF zview_entp_oe,
          lt_head_gc  TYPE STANDARD TABLE OF zv_cds_sd_gc,
          lt_likp     TYPE STANDARD TABLE OF zsd_likp_oe,
          lv_totlines TYPE i,
          lv_pag      TYPE i,
          lt_gcp      TYPE STANDARD TABLE OF zv_cds_gcp.

    SELECT *
     FROM zv_cds_gcp
     INTO TABLE @DATA(lt_items_gc)
    WHERE nrotrans EQ @iv_tknum AND
          lfart IN @lt_lfart.

    IF sy-subrc EQ 0.
      et_gc = VALUE #( FOR wa_item IN lt_items_gc
                          WHERE ( isimprimir <> 'X' )
                                ( nroentrega = wa_item-nroentrega
                                  pag        = wa_item-pag ) ).

      IF NOT et_gc[] IS INITIAL.
        ev_mensaje = 'Las OE no tiene salida de Mercancía:'.
        EXIT.
      ENDIF.

    ENDIF.

    rv_return = abap_true.

  ENDMETHOD.

  METHOD set_group_gc.
    DATA: lt_head     TYPE STANDARD TABLE OF zv_sd_gd_rxp, " zv_cds_sd_gc,
          lt_items    TYPE STANDARD TABLE OF zv_cds_gcp,
          lt_gck      TYPE STANDARD TABLE OF zsd_tb_gck,
          lt_gcp      TYPE STANDARD TABLE OF zsd_tb_gcp,
          lv_totlines TYPE i,
          lv_pag      TYPE i.

*    READ TABLE it_head
*          INTO DATA(ls_transp)
*          WITH KEY frkrl = abap_true.

    READ TABLE it_head INTO DATA(ls_transp) INDEX 1.

*    DATA(ls_gck) = VALUE zsd_tb_gck( tplst      = ls_transp-tplst
*                                     tdocumento = iv_document
*                                     tknum      = ls_transp-nrotrans
*                                     estado     = 'C'
*                                     ernam      = sy-uname
*                                     erdat      = sy-datum
*                                     erzet      = sy-uzeit ).
*    APPEND ls_gck TO et_gck.

    APPEND VALUE #( tplst      = ls_transp-tplst
                    tdocumento = iv_document
                    tknum      = ls_transp-nrotrans
                    estado     = 'C'
                    ernam      = sy-uname
                    erdat      = sy-datum
                    erzet      = sy-uzeit )
            TO et_gck.

*    IF ls_transp-frkrl EQ abap_true.

*    lv_pag = 1.
    ls_transp-pag = 1. " lv_pag.
*    lv_totlines = 0.

    APPEND ls_transp TO lt_head.
*    DATA(ls_gcp) = VALUE zsd_tb_gcp( tknum_c = ls_gck-tknum
*                                     tknum   = ls_transp-nrotrans
*                                     pagina  = ls_transp-pag
*                                     ernam   = sy-uname
*                                     erdat   = sy-datum
*                                     erzet   = sy-uzeit ).
*    APPEND ls_gcp TO et_gcp.

    APPEND VALUE #( tknum_c = ls_transp-nrotrans
                    tknum   = ls_transp-nrotrans
                    pagina  = ls_transp-pag
                    ernam   = sy-uname
                    erdat   = sy-datum
                    erzet   = sy-uzeit )
            TO et_gcp.

    LOOP AT it_items INTO DATA(ls_item).
      lv_totlines = lv_totlines + 1.

*      IF lv_totlines GT 19.
*        lv_pag = lv_pag + 1.
*        lv_totlines = 1.
*      ENDIF.

      ls_item-pag = ls_transp-pag. "lv_pag.
      APPEND ls_item TO lt_items.

*      IF ls_transp-pag NE lv_pag.
*        ls_transp-pag = lv_pag.
*          APPEND ls_transp TO lt_head.
*        ls_gcp = VALUE zsd_tb_gcp( tknum_c = ls_gck-tknum
*                                   tknum   = ls_transp-nrotrans
*                                   pagina  = ls_transp-pag
*                                   ernam   = sy-uname
*                                   erdat   = sy-datum
*                                   erzet   = sy-uzeit ).
*        APPEND ls_gcp TO et_gcp.
*      ENDIF.
    ENDLOOP.

*    ENDIF.

    IF NOT lt_head[] IS INITIAL.
      rv_return = abap_true.

      et_head[] = lt_head[].
      et_items[] = lt_items[].

    ENDIF.

  ENDMETHOD.

  METHOD upd_status_oe.
    is_docdig-estado = iv_status.

    MODIFY zsd_likp_oe FROM is_docdig.

    me->commit_work( ).
  ENDMETHOD.

  METHOD upd_status_gc.
    is_docdig-estado = iv_status.
    is_docdig-aenam  = sy-uname.
    is_docdig-aedat  = sy-datum.
    is_docdig-aezet  = sy-uzeit.

    UPDATE zsd_tb_gcp
       SET estado = is_docdig-estado
           url    = is_docdig-url
           aenam  = is_docdig-aenam
           aedat  = is_docdig-aedat
           aezet  = is_docdig-aezet
     WHERE tknum_c EQ is_docdig-tknum_c AND
           pagina  EQ is_docdig-pagina.

    me->commit_work( ).
  ENDMETHOD.

  METHOD set_log.
    INSERT zsd_tb_oe_log FROM is_oe_log.

    me->commit_work( ).
  ENDMETHOD.

  METHOD clear_log.
    DELETE FROM zsd_tb_oe_log.

    me->commit_work( ).
  ENDMETHOD.

  METHOD close_http.
    CALL METHOD io_http_client->close.
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

  METHOD get_dif_peso.
    DATA: lv_umren    TYPE  umren, ",
          lv_kilos    TYPE dec8_2,
          lv_pesopos  TYPE dec8_3,
          lv_peso     TYPE dec8_3,
          lv_galones  TYPE dec8_3,
          lv_galteo   TYPE dec8_3,
          lv_exitpeso TYPE abap_bool.

* Ini 04.02.2026 481 cfalcon DR3K981056
    TYPES: BEGIN OF lty_peso,
             sign   TYPE /bcv/fnd_sign_range,
             option TYPE /bcv/fnd_option,
             low    TYPE dec8_2,
             high   TYPE dec8_2,
           END OF lty_peso.

    DATA: lt_peso_rango TYPE  TABLE OF lty_peso.
*          ls_peso_rango TYPE lty_peso.
* Fin 04.02.2026 481 cfalcon DR3K981056

    DATA(go_peso) = NEW zcl_rf_pt_peso(  ).

    IF iv_doc EQ gc_status_e.
      SELECT *
        FROM zv_cds_sdra_01( p_vbeln = @iv_vbeln )
        INTO TABLE @DATA(lt_peso).
    ELSE.
      SELECT *
          FROM zv_cds_peso_vbrp( p_vbeln = @iv_vbeln )
          INTO TABLE @lt_peso.
    ENDIF.

* se suma la diferencia de peso del material con el peso de carga (rf)
    CLEAR: lv_kilos, lv_galones, lv_pesopos, lv_galteo.

    CLEAR: lt_peso_rango. "04.02.2026 481 cfalcon DR3K981056

    LOOP AT lt_peso INTO DATA(ws_peso).
      DATA(lv_pesorf) = go_peso->get_peso( iv_matnr = ws_peso-material
                                           iv_charg = ws_peso-lote ).

      IF lv_pesorf IS INITIAL OR lv_pesorf LT 0.
        lv_exitpeso = abap_false.
      ENDIF.

      lt_peso_rango = VALUE #( ( sign   = 'I'  "04.02.2026 481 cfalcon DR3K981056
                                 option = 'BT'
                                 high   = ws_peso-pesobruto + ( ( ws_peso-pesobruto * 20 ) / 100 )
                                 low    = ws_peso-pesobruto - ( ( ws_peso-pesobruto * 20 ) / 100 ) ) ).

      lv_galteo = lv_galteo + ws_peso-volumen.
      lv_galones = lv_galones + ws_peso-galones.
      lv_pesopos = lv_pesopos + ( ws_peso-volumen * ws_peso-pesobruto ).
      lv_peso = ws_peso-pesodif + lv_pesorf.
      lv_kilos = lv_kilos + ( lv_peso * ws_peso-volumen ).

* Ini 04.02.2026 481 cfalcon DR3K981056
      IF lv_peso NOT IN lt_peso_rango.

        mv_men_1 = | El Material { ws_peso-material } Lote { ws_peso-lote }|.

        mv_men_2 = | corregir el peso { lv_peso }|.

        ls_message = VALUE symsg( msgty = 'W'
                                  msgid = '02'
                                  msgno = '002'
                                  msgv1 = mv_men_1
                                  msgv2 = mv_men_2 ).

        APPEND ls_message TO lt_message.

        me->set_message( lt_message ).
*        RETURN.

      ENDIF.
* Fin 04.02.2026 481 cfalcon DR3K981056

    ENDLOOP.

    es_gc-volum = lv_galteo.
    es_gc-galones = lv_galones.
    es_gc-pesototal = lv_pesopos.
    es_gc-kgcarga = lv_kilos.
  ENDMETHOD.

  METHOD send_msg_mail.
    DATA: xxml_out TYPE xstring.

    DATA: len    TYPE sood-objlen,
          length TYPE  i.

    DATA: binary_content TYPE solix_tab.

    DATA: text  TYPE bcsy_text,
          text1 TYPE bcsy_text.

    DATA: xtext TYPE STANDARD TABLE OF solix .

    DATA: lo_send_request TYPE REF TO cl_bcs,
          lo_document     TYPE REF TO cl_document_bcs,
          sender          TYPE REF TO if_sender_bcs,
          recipient       TYPE REF TO if_recipient_bcs.

    DATA: sent_to_all TYPE os_boolean.

    DATA: atta_sub     TYPE sood-objdes,
          app_type(50).

    DATA: bcs_message TYPE string.

    DATA: lv_asunto   TYPE so_obj_des,
          lv_cuerpo   TYPE bcsy_text,
          lt_receiver TYPE TABLE OF adr6-smtp_addr.

    DATA: lv_sender TYPE adr6-smtp_addr.

    CONSTANTS: lc_htm    TYPE char03 VALUE 'HTM',
               lc_id     TYPE tdid VALUE 'ST',
               lc_object TYPE tdobject VALUE 'TEXT'.

*        lv_subject   TYPE so_obj_des,
    DATA lv_att_title TYPE so_obj_des.

    DATA: lt_lines  TYPE TABLE OF tline,
          ls_header TYPE thead.

    me->find_email_address(
      EXPORTING
        iv_tplst  = iv_tplst
*        iv_tipdoc = iv_tipdoc
        is_oe_log = is_oe_log
      IMPORTING
        et_addr   = lt_receiver ).

    me->read_body_mail(
      IMPORTING
        es_header   = ls_header
        et_lines    = lt_lines ).

* Convert Text template to HTML - email body
    DATA: lt_html_text  TYPE TABLE OF htmlline,
          lt_body_email TYPE soli_tab.

    DATA lv_thead TYPE thead .

    CALL FUNCTION 'CONVERT_ITF_TO_HTML'
      EXPORTING
        i_header       = ls_header
        i_title        = 'Falla de comunicación Servicio SL'
      TABLES
        t_itf_text     = lt_lines
        t_html_text    = lt_html_text
      EXCEPTIONS
        syntax_check   = 1
        replace        = 2
        illegal_header = 3
        OTHERS         = 4.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    me->get_det_error(
      EXPORTING
        iv_tplst      = iv_tplst
        is_oe_log     = is_oe_log
      CHANGING
        et_body_email = lt_html_text ).

    lt_body_email[] = lt_html_text[].

    TRY.
        CLEAR lo_send_request.

        lo_send_request = cl_bcs=>create_persistent( ).

* Add sender to the request
        lo_send_request->set_sender( i_sender = cl_sapuser_bcs=>create( sy-uname ) ).

* Add recipients to the request
        CLEAR lv_sender.

        LOOP AT lt_receiver INTO lv_sender. " DATA(ls_receiver). " ASSIGNING FIELD-SYMBOL(<ls_receiver>).
          lo_send_request->add_recipient( i_recipient = cl_cam_address_bcs=>create_internet_address( lv_sender )
                                          i_express   = abap_true ).
        ENDLOOP.

        CLEAR lo_document.

        lo_document = cl_document_bcs=>create_document( i_type = lc_htm
                                                        i_subject = iv_asunto
                                                        i_text = lt_body_email ).

*                                                      lo_document = cl_docu

        CALL METHOD lo_send_request->set_document( lo_document ).

        CALL METHOD lo_send_request->set_status_attributes
          EXPORTING
            i_requested_status = gc_status_e
            i_status_mail      = gc_status_e.

        CALL METHOD lo_send_request->set_send_immediately( 'X' ).
* ---------- send document ---------------------------------------
        CALL METHOD lo_send_request->send(
          EXPORTING
            i_with_error_screen = 'X'
          RECEIVING
            result              = sent_to_all ).

        IF sent_to_all = 'X'.
          MESSAGE i208(00) WITH 'Correo enviado con la solicitud.'.
        ENDIF.

        COMMIT WORK.

      CATCH cx_bcs INTO DATA(lo_bcs_exception).
        bcs_message = lo_bcs_exception->get_text( ).
        WRITE : |Type: { lo_bcs_exception->error_type } / Message { lo_bcs_exception->get_text( ) }|.
        MESSAGE i208(00) WITH 'Error envio: Revise direcciones de correo asociadas'.
        EXIT.

    ENDTRY.

  ENDMETHOD.

  METHOD find_email_address.
    DATA: lt_user_ti TYPE TABLE OF zsd_tb_send_mail,
          ls_user_ti TYPE zsd_tb_send_mail.

    REFRESH lt_user_ti.
    CLEAR ls_user_ti.

    SELECT *
      INTO TABLE @lt_user_ti
      FROM zsd_tb_send_mail
     WHERE bukrs EQ @iv_tplst AND
           tdocumento EQ @is_oe_log-tdocumento AND
           activo EQ @abap_true.

    IF sy-subrc NE 0.
      ls_user_ti = VALUE zsd_tb_send_mail( bukrs = iv_tplst
                                           tdocumento = is_oe_log-tdocumento
                                           addr6 = 'carlos_falcon@corimon.com'
                                           activo = abap_true
                                           ernam = sy-uname
                                           erdat = sy-datum
                                           erzet = sy-uzeit ).
      APPEND ls_user_ti TO lt_user_ti.

      ls_user_ti = VALUE zsd_tb_send_mail( bukrs = iv_tplst
                                           tdocumento = is_oe_log-tdocumento
                                           addr6 = 'pedro_marquez@corimon.com'
                                           activo = abap_true
                                           ernam = sy-uname
                                           erdat = sy-datum
                                           erzet = sy-uzeit ).
      APPEND ls_user_ti TO lt_user_ti.

      ls_user_ti = VALUE zsd_tb_send_mail( bukrs = iv_tplst
                                           tdocumento = is_oe_log-tdocumento
                                           addr6 = 'william_leon@corimon.com'
                                           activo = abap_true
                                           ernam = sy-uname
                                           erdat = sy-datum
                                           erzet = sy-uzeit ).
      APPEND ls_user_ti TO lt_user_ti.

      MODIFY zsd_tb_send_mail FROM TABLE lt_user_ti.

      me->commit_work( ).
    ENDIF.

    CLEAR ls_user_ti.

    LOOP AT lt_user_ti INTO ls_user_ti.
      APPEND ls_user_ti-addr6 TO et_addr.
    ENDLOOP.
  ENDMETHOD.

  METHOD read_body_mail.
    CONSTANTS: lc_htm    TYPE char03 VALUE 'HTM',
               lc_id     TYPE tdid VALUE 'ST',
               lc_name   TYPE tdobname VALUE 'ZST_EMAIL_FD_ERROR',
               lc_object TYPE tdobject VALUE 'TEXT'.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        client                  = sy-mandt  " Mandante
        id                      = lc_id     " ID del texto a leer
        language                = sy-langu  " Idioma del texto a leer
        name                    = lc_name   " Nombre del texto a leer
        object                  = lc_object " Objeto del texto a leer
      IMPORTING
        header                  = es_header " Cabecera del texto leído
      TABLES
        lines                   = et_lines  " Líneas del texto leído
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7
        OTHERS                  = 8.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

*********Replacing variables in template***********
    CALL FUNCTION 'INIT_TEXTSYMBOL'.

    DATA(lv_count) = lines( et_lines ).

    CALL FUNCTION 'REPLACE_TEXTSYMBOL'
      EXPORTING
        endline   = lv_count
        startline = 1
      TABLES
        lines     = et_lines.
***************************************************

*    CLEAR lv_name.
  ENDMETHOD.

  METHOD get_det_error.
    DATA: lv_text     TYPE string,
*          lv_menge(13) TYPE c,
          lt_lines    TYPE TABLE OF tline,
          lt_line     TYPE  tline,
*          lv_mantr(11) TYPE c,
          lv_hora     TYPE  tims,
          lv_am_pm(2) TYPE c,
          lv_erdat    TYPE erdat.

    CLEAR: lv_text.

    DESCRIBE TABLE et_body_email LINES DATA(lv_line).
    DELETE et_body_email INDEX lv_line.

    DESCRIBE TABLE et_body_email LINES lv_line.
    DELETE et_body_email INDEX lv_line.

    APPEND '<table>' TO et_body_email.

    APPEND '<tr>' TO et_body_email.

    APPEND '<td width=100px><b>Filial</b></td>' TO et_body_email.
    APPEND '<td><b>Tip. Doc.</b></td>' TO et_body_email.
    APPEND '<td aling=center><b>Documento</b></td>'  TO et_body_email.
    APPEND '<td aling=center><b>Página</b></td>'  TO et_body_email.
    APPEND '<td aling=center><b>Mensaje</b></td>'  TO et_body_email.
    APPEND '<td aling=center><b>Fecha</b></td>'  TO et_body_email.
    APPEND '<td aling=center><b>Hora</b></td>'  TO et_body_email.

    APPEND '</tr>' TO et_body_email.

    APPEND '<tr>' TO et_body_email.

    lv_erdat = is_oe_log-erdat.

    WRITE sy-datum TO lv_erdat DD/MM/YYYY.

    lv_hora = is_oe_log-erzet.

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

    WRITE lv_hora TO lv_hora ENVIRONMENT TIME FORMAT.
*    WRITE lv_hora TO lv_hora hh:mm:ss.

*Filial
    CONCATENATE '<td aling=center>' iv_tplst '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td aling=center>' is_oe_log-tdocumento '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td>' is_oe_log-ndocumento '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td>' is_oe_log-pagina '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td>' is_oe_log-mensaje '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td>' lv_erdat '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    CONCATENATE '<td align=right>' lv_hora '</td>' INTO lv_text.
    APPEND lv_text TO et_body_email.

    APPEND '</tr>' TO et_body_email.
    APPEND '</table>' TO et_body_email.
    APPEND '</body>' TO et_body_email.
    APPEND '</html>' TO et_body_email.
  ENDMETHOD.

ENDCLASS.
