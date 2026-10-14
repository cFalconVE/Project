*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZVAP_DOMINIO_VAL................................*
TABLES: ZVAP_DOMINIO_VAL, *ZVAP_DOMINIO_VAL. "view work areas
CONTROLS: TCTRL_ZVAP_DOMINIO_VAL
TYPE TABLEVIEW USING SCREEN '0100'.
DATA: BEGIN OF STATUS_ZVAP_DOMINIO_VAL. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZVAP_DOMINIO_VAL.
* Table for entries selected to show on screen
DATA: BEGIN OF ZVAP_DOMINIO_VAL_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZVAP_DOMINIO_VAL.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVAP_DOMINIO_VAL_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZVAP_DOMINIO_VAL_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZVAP_DOMINIO_VAL.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZVAP_DOMINIO_VAL_TOTAL.

*.........table declarations:.................................*
TABLES: ZAP_DOMINIOS_VAL               .
