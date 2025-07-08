namespace ao.recap;

using {ao.recap as eam} from '@alphaoak/recap-plugin';


entity SafetyInspections {
    key ID             : Integer;
        sapWorkOrderId : String(50);
        description    : String(500);
        status         : String(50);
        createdAt      : DateTime;
        updatedAt      : DateTime;
}


extend eam.Jobs with {
    extensionField    : String(50);
    safetyInspections : Association to many SafetyInspections
                            on $self.sapWorkOrderId = safetyInspections.sapWorkOrderId;
};
