namespace ao.recap;

entity Jobs {
    key ID             : UUID;
        sapWorkOrderId : String(50);
        description    : String(500);
        effort         : Double;
        startedAt      : DateTime;
        finishedAt     : DateTime;
        createdAt      : DateTime;
        updatedAt      : DateTime;
}
