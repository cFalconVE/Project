@AbapCatalog.sqlViewName: 'ZCDS_ORG_VTAS'
@AbapCatalog.compiler.CompareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Vista de Organización de Ventas'
@Metadata.ignorePropagatedAnnotations: true
define view zview_org_vtas 
    as select from t001 as so
// País
    association[1] to t005t as pa  on $projection.idioma = pa.spras
                                  and $projection.codPais = pa.land1
// Rif
    association[1] to t001z as ri on  $projection.orgVtas = ri.bukrs
                                  and ri.party = 'VE_RIF'
// Direcciones
    association[1] to adrc as di on $projection.adrnr = di.addrnumber
// Correo
    association[1] to adr6 as co on $projection.adrnr = co.addrnumber   
                               
{
    key so.bukrs as orgVtas,
        so.spras as idioma,
        so.land1 as codPais,
        so.adrnr,
        ri.paval as rif,
        concat(di.name1,  concat(' ', di.name2)) as razonSocial,
//    di.street && ' ' && di.str_suppl1 as direccion
//    concat_with_space( di.street, di.str_suppl1, 1 ) as dir1
        concat(di.street, concat(' ', di.str_suppl1)) as dir1,
        concat(di.str_suppl2, concat(' ', di.str_suppl3)) as dir2,
        concat(di.post_code1, concat(' ', di.city2)) as dir3,
        pa.landx as pais,
        di.city1 as ciudad,
        di.tel_number as telefono,
        concat(pa.landx, concat(' - ', di.city1)) as paisCiudad,
        co.smtp_addr as correOrg
}
