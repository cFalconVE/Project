CLASS lcl_doc_dig DEFINITION.

  PUBLIC SECTION.

    CONSTANTS:
      gc_parvw TYPE parvw VALUE 'EM'.

    TYPES:
      BEGIN OF st_vbpa,
        vbeln TYPE vbeln_vl,
        parvw TYPE parvw,
        kunnr TYPE kunnr,
        adrnr TYPE adrnr,
      END OF st_vbpa,

      BEGIN OF ty_nroentrega,
        sign     TYPE /bcv/fnd_sign_range,
        option   TYPE /bcv/fnd_option,
        low(10)  TYPE c,
        high(10) TYPE c,
      END OF ty_nroentrega,

      tt_entrega TYPE STANDARD TABLE OF ty_nroentrega,
      tt_vbpa    TYPE STANDARD TABLE OF st_vbpa
                        WITH NON-UNIQUE KEY vbeln parvw.

    DATA:
      gv_vbeln   TYPE tt_entrega READ-ONLY,
      destino_oe TYPE tt_vbpa READ-ONLY.

    DATA lt_adrnr TYPE st_vbpa.

*    CLASS-DATA:
*      gt_vbpa    TYPE SORTED TABLE OF st_vbpa
*                    WITH NON-UNIQUE KEY vbeln.

    METHODS: constructor
      IMPORTING
                i_vbeln TYPE tt_entrega
      RAISING   cx_sy_itab_line_not_found. "cx_abap_invalid_value.

    CLASS-METHODS
      get_adrnr_entrega
        IMPORTING it_vbeln        TYPE tt_entrega
        RETURNING VALUE(r_result) TYPE tt_vbpa.

  PROTECTED SECTION.

  PRIVATE SECTION.

ENDCLASS.

CLASS lcl_doc_dig IMPLEMENTATION.

  METHOD constructor.

    me->gv_vbeln = i_vbeln.

    TRY.
        destino_oe = get_adrnr_entrega( it_vbeln = i_vbeln ).

      CATCH cx_sy_itab_line_not_found.

    ENDTRY.

  ENDMETHOD.

  METHOD get_adrnr_entrega.
    CONSTANTS lc_langu TYPE langu VALUE 'S'.
    DATA lv_parvw TYPE parvw.

    TRY.
        IF sy-langu EQ 'S'.
          CALL FUNCTION 'CONVERSION_EXIT_PARVW_INPUT'
            EXPORTING
              input  = gc_parvw
            IMPORTING
              output = lv_parvw.
        ELSE.
          CALL FUNCTION 'RV_CONVERSION_EXIT_PARVW_IN'
            EXPORTING
              pabez = gc_parvw
              spras = lc_langu
            IMPORTING
              parvw = lv_parvw.
        ENDIF.

        IF sy-subrc EQ 0.
          SELECT vbeln, tpart~parvw, kunnr, adrnr
            FROM vbpa
            INNER JOIN tpart ON vbpa~parvw EQ tpart~parvw
*            AND
*                                tpart~spras EQ @lc_langu
           WHERE vbeln IN @it_vbeln AND
                 tpart~parvw EQ @lv_parvw
                  AND tpart~spras EQ @lc_langu
            INTO TABLE @r_result.

*          SELECT *
*            FROM zv_adrnr_entrega
*            INTO TABLE @r_result
*           WHERE vbeln IN @it_vbeln AND
*                 parvw EQ @lv_parvw.
        ELSE.
          RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
        ENDIF.

      CATCH cx_sy_itab_line_not_found.

    ENDTRY.

  ENDMETHOD.

ENDCLASS.
