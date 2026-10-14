@AbapCatalog.sqlViewName: 'ZCDS_DOC_FLUJO'
@AbapCatalog.compiler.CompareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista Flujo de Documento'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zview_doc_flujo 
    with parameters
        p_vbelv : vbelv
//        p_vbtyp : vbtyp_n
    as 
    select distinct from vbfa as fd
// Factura: Datos de posición
//        association[1] to vbrp as pf on $projection.factura = pf.vbeln

{
    key fd.vbeln as ndroDocumento,
//        pf.vbeln as nroFactura,
        fd.vbtyp_n
//        pf.matnr as matnr,
//        pf.vrkme,
//        pf.fkimg
    
} where fd.vbelv = $parameters.p_vbelv
//    and fd.vbtyp_n = $parameters.p_vbtyp
