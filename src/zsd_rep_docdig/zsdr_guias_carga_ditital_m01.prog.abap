*&---------------------------------------------------------------------*
*&  Include           ZSDR_GUIAS_CARGA_DITITAL_M01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9000 OUTPUT.
  SET PF-STATUS 'SG_9000'.
  SET TITLEBAR 'TG_9000'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9000 INPUT.
  CASE gv_ucomm.
    WHEN '&REF'.
      IF o_ref IS BOUND.
        o_ref->get_data( ).
      ENDIF.
      lcl_report_handler=>refresh_data( ).
    WHEN '&BACK' OR '&CANC'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN '&EXIT'.
      LEAVE PROGRAM.
  ENDCASE.

  CALL METHOD cl_gui_cfw=>flush.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  CREATE_OBJECT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE create_object OUTPUT.

  lcl_report_handler=>create_object( ).

ENDMODULE.
