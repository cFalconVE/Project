*&---------------------------------------------------------------------*
*&  Include  zsd_doc_util_cl
*&---------------------------------------------------------------------*
CLASS lcl_dd_util DEFINITION.
  PUBLIC SECTION.

    TYPES:
      st_lipk_oe TYPE zsd_likp_oe,
      tt_lipk_oe TYPE STANDARD TABLE OF st_lipk_oe.

    CLASS-DATA lt_lipk_oe TYPE tt_lipk_oe.

    METHODS:
      constructor
        RAISING
          cx_abap_invalid_value,

      init.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS:
      get_data,
      upd_data,
      commit_work.

ENDCLASS.

CLASS lcl_dd_util IMPLEMENTATION.

  METHOD constructor.
    TRY.
        get_data( ).

        IF lt_lipk_oe[] IS NOT INITIAL.
          upd_data( ).
        ENDIF.
      CATCH cx_abap_invalid_value.
    ENDTRY.

  ENDMETHOD.

  METHOD init.
    get_data( ).

    IF lt_lipk_oe[] IS NOT INITIAL.
      upd_data( ).
    ENDIF.

  ENDMETHOD.

  METHOD get_data.
    SELECT *
      FROM zsd_likp_oe
      INTO TABLE @lt_lipk_oe.
  ENDMETHOD.

  METHOD upd_data.
    LOOP AT lt_lipk_oe ASSIGNING FIELD-SYMBOL(<fs_lipk_oe>).
      IF <fs_lipk_oe>-femision IS INITIAL.
        MOVE:
          <fs_lipk_oe>-aedat TO <fs_lipk_oe>-femision,
          <fs_lipk_oe>-aezet TO <fs_lipk_oe>-hemision.

        MODIFY zsd_likp_oe FROM <fs_lipk_oe>.
      ENDIF.
    ENDLOOP.

    commit_work( ).
  ENDMETHOD.

  METHOD commit_work.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = abap_true.
  ENDMETHOD.

ENDCLASS.
