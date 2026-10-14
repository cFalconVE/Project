CLASS zcl_sd_stat_transp DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA: mv_transp TYPE zsd_st_stage READ-ONLY.

    CLASS-METHODS:
      update_stage
        IMPORTING
          is_transp        TYPE zsd_st_stage
        RETURNING
          VALUE(rv_return) TYPE abap_bool.

    METHODS:
      constructor
        IMPORTING
          is_transp TYPE zsd_st_stage,

      udt_uni.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.

CLASS zcl_sd_stat_transp IMPLEMENTATION.

  METHOD constructor.
    me->mv_transp = is_transp.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = is_transp-tknum
      IMPORTING
        output = mv_transp-tknum.

*    mv_transp-date = sy-datum.
*    mv_transp-time = sy-uzeit.

  ENDMETHOD.

  METHOD update_stage.
    TYPES:
      BEGIN OF ty_time_utc,
        date_trans    TYPE d,
        time_trans    TYPE t,
*        date_utc      TYPE d,
*        time_utc      TYPE t,
        time_zone     TYPE tzone,
        timestamp_utc TYPE char14,
      END OF ty_time_utc.

    DATA:
      ls_time_utc         TYPE ty_time_utc,
      ls_headerdata       TYPE bapishipmentheader,
      ls_headerdataaction TYPE bapishipmentheaderaction,
      lt_deadline         TYPE STANDARD TABLE OF bapishipmentheaderdeadline,
      lt_deadlineact      TYPE STANDARD TABLE OF bapishipmentheaderdeadlineact,
      lt_return           TYPE STANDARD TABLE OF bapiret2,
      ls_return           TYPE bapiret2.

** Limpieza General
    CLEAR: ls_return.

    REFRESH:
        lt_return,
        lt_deadline,
        lt_deadlineact.

    ls_headerdata = VALUE #( shipment_num = is_transp-tknum ).
    ls_headerdataaction = VALUE #( shipment_num = is_transp-tknum ).

    ls_time_utc = VALUE #(
        date_trans = is_transp-date_stage
        time_trans = is_transp-time_stage
        time_zone = VALUE #( mandt = sy-mandt
                             zone1 = sy-zonlo(3) )
        timestamp_utc = is_transp-date_stage && is_transp-time_stage ).

** Estatus a Marcar
    CASE is_transp-sttrg.
*      WHEN '1'. "Planificacion Necesidad
*
*        MOVE  p_check_cab  TO  wa_headerdata-status_plan.
*        MOVE  p_check_acc  TO  wa_headerdataaction-status_plan.
*
*      WHEN '2'. "Registro
*
*        MOVE  p_check_cab  TO  wa_headerdata-status_checkin.
*        MOVE  p_check_acc  TO  wa_headerdataaction-status_checkin.

      WHEN '3'. "Inicio Carga

        MOVE  'X'  TO  ls_headerdata-status_load_start.
        MOVE  'C'  TO  ls_headerdataaction-status_load_start.

        DATA(ls_deadline) =
            VALUE bapishipmentheaderdeadline(
                    time_type = 'HDRSTLSADT'
                    time_stamp_utc = ls_time_utc-timestamp_utc
                    time_zone =  ls_time_utc-time_zone-zone1 ).


*        APPEND ls_deadline TO lt_shipmentheaderdeadline.

      WHEN '4'. "Fin Carga

        MOVE  'X'  TO  ls_headerdata-status_load_end.
        MOVE  'C'  TO  ls_headerdataaction-status_load_end.

        ls_deadline =
            VALUE bapishipmentheaderdeadline(
                    time_type = 'HDRSTLEADT'
                    time_stamp_utc = ls_time_utc-timestamp_utc
                    time_zone =  ls_time_utc-time_zone-zone1 ).

*        APPEND ls_deadline TO lt_shipmentheaderdeadline.

      WHEN '5'. "Despacho Expedicion

        MOVE  'X'  TO  ls_headerdata-status_compl.
        MOVE  'C'  TO  ls_headerdataaction-status_compl.

        ls_deadline =
           VALUE bapishipmentheaderdeadline(
                   time_type = 'HDRSTCADT'
                   time_stamp_utc = ls_time_utc-timestamp_utc
                   time_zone =  ls_time_utc-time_zone-zone1 ).

*        APPEND ls_deadline TO lt_shipmentheaderdeadline.

      WHEN '6'. "Inicio Transporte

        MOVE  'X'  TO  ls_headerdata-status_shpmnt_start.
        MOVE  'C'  TO  ls_headerdataaction-status_shpmnt_start.

        ls_deadline =
           VALUE bapishipmentheaderdeadline(
                   time_type = 'HDRSTSSADT'
                   time_stamp_utc = ls_time_utc-timestamp_utc
                   time_zone =  ls_time_utc-time_zone-zone1 ).

*        APPEND ls_deadline TO lt_shipmentheaderdeadline.

      WHEN '7'. "Fin Transporte

        MOVE  'X'  TO  ls_headerdata-status_shpmnt_end.
        MOVE  'C'  TO  ls_headerdataaction-status_shpmnt_end.

        ls_deadline =
           VALUE bapishipmentheaderdeadline(
                   time_type = 'HDRSTSEADT'
                   time_stamp_utc = ls_time_utc-timestamp_utc
                   time_zone =  ls_time_utc-time_zone-zone1 ).

*        APPEND ls_deadline TO lt_shipmentheaderdeadline.

    ENDCASE.

    APPEND ls_deadline TO lt_deadline.

    APPEND VALUE #( time_type = 'C'
                    time_stamp_utc = 'C'
                    time_zone = 'C' )
        TO lt_deadlineact.

    TRY.
        CALL FUNCTION 'BAPI_SHIPMENT_CHANGE'
          EXPORTING
            headerdata           = ls_headerdata
            headerdataaction     = ls_headerdataaction
          TABLES
            headerdeadline       = lt_deadline
            headerdeadlineaction = lt_deadlineact
            return               = lt_return.

      CATCH cx_root INTO DATA(cx).
        WRITE: / cx->get_text( ).
    ENDTRY.

    IF sy-subrc EQ 0.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
    ENDIF.

    IF lt_return[] IS NOT INITIAL.

*      DATA(ls_return) = lt_return[ type = 'E' ].

      IF sy-subrc EQ 0.

*        DATA(ls_stage_log) = VALUE zsd_tb_stage_log(
*             tknum = is_transp-tknum
*             sttrg = is_transp-sttrg
*             date_stage = is_transp-date_stage
*             time_stage = is_transp-time_stage
*             message = ls_return-message ).

*        INSERT zsd_tb_stage_log FROM ls_stage_log.

*        IF sy-subrc EQ 0.
*          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*            EXPORTING
*              wait = 'X'.
*        ENDIF.
*
*        EXIT.

      ENDIF.

    ENDIF.

    LOOP AT lt_return INTO ls_return.
      WRITE: / ls_return-type, ls_return-message.
    ENDLOOP.

    rv_return = abap_true.
  ENDMETHOD.

  METHOD udt_uni.
    IF sy-uname EQ '700-009'.

      SELECT * " bukrs, tdocumento, vbeln, zieme
        FROM zsd_incid_desp
        INTO TABLE @DATA(lt_inci).

      LOOP AT lt_inci ASSIGNING FIELD-SYMBOL(<fs_inci>).
        " Llamada a la función estándar
        CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
          EXPORTING
            input          = <fs_inci>-zieme
            language       = sy-langu
          IMPORTING
            output         = <fs_inci>-zieme
          EXCEPTIONS
            unit_not_found = 1
            OTHERS         = 2.

        IF sy-subrc EQ 0.
          MODIFY zsd_incid_desp FROM <fs_inci>.
        ENDIF.

      ENDLOOP.

      COMMIT WORK.

    ENDIF.

  ENDMETHOD.

ENDCLASS.
