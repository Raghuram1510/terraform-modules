from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult, CheckCategories


class EnforceNamingConvention(BaseResourceCheck):
    def __init__(self):
        name = "Ensure resources follow naming convention: {cluster_name}-{environment}-*"
        id = "CKV_CUSTOM_1"
        supported_resources = ['aws_*']
        categories = [CheckCategories.CONVENTION]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Validates that resource name follows pattern: {cluster_name}-{environment}-*
        Example: my-cluster-prod-vpc
        """
        name = conf.get('name')
        tags = conf.get('tags')
        
        if isinstance(tags, list) and len(tags) > 0:
            tags = tags[0]
        
        resource_name = None
        if name:
            resource_name = name[0] if isinstance(name, list) else name
        elif tags and isinstance(tags, dict):
            resource_name = tags.get('Name')
        
        if not resource_name:
            return CheckResult.PASSED
        
        parts = str(resource_name).split('-')
        if len(parts) >= 3:
            return CheckResult.PASSED
        
        return CheckResult.FAILED


check = EnforceNamingConvention()