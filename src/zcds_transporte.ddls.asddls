@AbapCatalog.sqlViewName: 'ZCDS_TRANSPORTE'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista del Transportista'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view zview_transporte 
    as 
    select from lfa1 as tr
// 
    association[1] to adrc as de on $projection.adrnr = de.addrnumber
//
    association[0..1] to adr6 as tr6  on $projection.adrnr = tr6.addrnumber
                                     and tr6.flgdefault = 'X'
                                     and tr6.persnumber = ' '
////                                    
//    association[0..1] to kna1 as mc on $projection.lifnr = mc.kunnr
////
//    association[0..1] to adr6 as cl6  on $projection.adrClient = cl6.addrnumber
//                                     and cl6.flgdefault = 'X'
//                                     and cl6.persnumber = ' '
//
    association[1] to t005t as t5 on  $projection.land1 = t5.land1
                                  and t5.spras = 'S'
{
    key tr.lifnr,
        tr.land1, 
        tr.adrnr,
        concat(de.name1, concat(' ', de.name2)) as nameTrans,
        concat(de.str_suppl1, concat(' ', de.str_suppl2)) as dirTrans1,
        concat(de.str_suppl3, concat(' ', de.post_code1)) as dirTrans2,
        de.city2 as cityTran2,
        concat(t5.landx, concat(' - ', de.city1)) as paisTrans,
        tr6.smtp_addr as correoTrans
//        mc.adrnr as adrClient
//        cl6.smtp_addr as correoDestino
}
