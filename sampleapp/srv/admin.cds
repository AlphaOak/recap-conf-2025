using {ao.recap as eam }from '../db/app-dbmodel';

service AdminService{

    entity Jobs as projection on eam.Jobs;
    entity SafetyInspections as projection on eam.SafetyInspections;

    entity Bla {
        key ID : Integer;
        Name : String(100);
    }
}