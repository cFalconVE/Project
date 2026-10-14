//*&---------------------------------------------------------------------*
//*&  CDS:        ZV_CDS_PESO_VBRP
//*&  Fecha:      14.04.2025
//*&  Autor:      700-009 : CFALCON
//*&  ServiDesk:  55601
//*&  Transporte: DR3K978349
//*----------------------------------------------------------------------*
//*    Bitacora de actualización
//*----------------------------------------------------------------------*
//*&   Fecha       Caso   User    Orden      Descripción
//*&---------------------------------------------------------------------*
//*&
//*&
//*&---------------------------------------------------------------------*
@AbapCatalog.sqlViewName: 'ZSD_CDS_W_VBRP'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista para el peso de materiales de la factura'
@Metadata.ignorePropagatedAnnotations: true
define view zv_cds_peso_vbrp 
    with parameters 
    p_vbeln : vbeln_vl // abap.char( 10 )
as select from mara as m
inner join vbrp as f
    on m.matnr = f.matnr
{
    key vbeln               as factura,
    key posnr               as posicion,
        f.matnr             as material,
        charg               as lote,
        f.fklmg             as volumen,
        f.volum             as galones,
        m.brgew             as PesoBruto,
        m.ntgew             as PesoNeto,
        (m.brgew - m.ntgew) as PesoDif
} where f.vbeln = $parameters.p_vbeln
    and f.fklmg > 0
