@AbapCatalog.sqlViewName: 'ZCDS_ENT_PO_OE'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista de Posiciones de entregas OE'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zview_enr_po_oe 
//    with parameters
//        p_tknum : tknum
    as select from vttp as vp  // Posiciones: Transporte
// Encabezado: Entrega
    association[0..1] to likp as lk on $projection.nroEntrega = lk.vbeln
//Documento Comercial
     association[1] to vbuk as dc on $projection.nroEntrega = dc.vbeln
    
    association[1] to vbfa as fd on $projection.nroEntrega = fd.vbeln
//// Posiciones: Entrega
//    association[0..1] to lips as lp on $projection.nroEntrega = lp.vbeln
//    association[0..*] to zview_entp_oe as lp on $projection.nroEntrega = lp.
//Destinatrario: Información del cliente
//    association[1] to zview_transporte as tr on $projection.kunnr = tr.lifnr
   
{
    key vp.tknum as nroTransporte,
        vp.vbeln as nroEntrega,
//    key lk.vbeln as nroEntrega,
//        lk.vbeln,
        lk.lfart,
        dc.gbstk as docConcluido,
        case dc.gbstk
        when 'C'
            then
            cast( 'X' as abap.char( 1 ) )
        else
            cast( '' as abap.char( 1 ) ) 
        end as isImprimir,
        fd.vbelv as nroPedido,
        lk.kunnr,
        lk.kunag,
        lk.waerk,       
        count(*) as nroPosiciones
//        tr
} 
//where lk.lfart = 'ZECN' or lk.lfart = 'NL'
//vp.tknum = $parameters.p_tknum
group by vp.tknum, 
         vp.vbeln,
         lk.lfart,
         dc.gbstk,
         fd.vbelv,
         lk.kunnr,
         lk.kunag,
         lk.waerk
