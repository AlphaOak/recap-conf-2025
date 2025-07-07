using {ao.recap as recap} from '../db/eam-core';

service ApiService {

    entity Jobs as projection on recap.Jobs;

}
