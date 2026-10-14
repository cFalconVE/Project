@AbapCatalog.sqlViewName: 'ZCDS_ENTREGAS'
@AbapCatalog.compiler.CompareFilter: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista Documento de Entrega'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zview_doc_entrega
    as 
    select from likp as fd
// Factura: Datos de posición
        association[0..1] to lips as pe on $projection.nroEntrega = pe.vbeln
        
        association[0..1] to tvro as ru on $projection.route = ru.route
        
        association[1] to kna1 as tr on $projection.kunnr = tr.kunnr
        
//        association[1] to adrc  as dir on $projection.adrnr = dir.addrnumber  

{
    key fd.vbeln as nroEntrega,
        fd.volum,
        fd.btgew,
        fd.lfart,
        fd.route,
        fd.kunnr,
        fd.kunag,
        ru.distz as distancia,
        tr.adrnr,
//        dir.city1 as ciudad,
//        dir.region,
//        dir.langu,
        sum( pe.lfimg ) as bultos
} group by fd.vbeln,
           fd.volum,
           fd.btgew,
           fd.lfart,
           fd.route,
           fd.kunnr,
           fd.kunag,
           ru.distz,
           tr.adrnr 
