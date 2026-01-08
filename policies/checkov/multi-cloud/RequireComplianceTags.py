from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult, CheckCategories


class RequireComplianceTags(BaseResourceCheck):
    def __init__(self):
        name = "Ensure resources have Compliance tag (HIPAA, SOC2, or CIS)"
        id = "CKV_CUSTOM_2"
        supported_resources = ['aws_*', 'azurerm_*', 'google_*']
        categories = [CheckCategories.CONVENTION]
        super().__init__(name=name, id=id, categories=categories, supported_resources=supported_resources)

    def scan_resource_conf(self, conf):
        """
        Validates that resource has a 'Compliance' tag
        """
        tags = conf.get('tags')
        
        if isinstance(tags, list) and len(tags) > 0:
            tags = tags[0]
        
        if not tags or not isinstance(tags, dict):
            return CheckResult.FAILED
        
        compliance_tag = tags.get('Compliance')
        
        if not compliance_tag:
            return CheckResult.FAILED
        
        compliance_value = str(compliance_tag).upper()
        if any(framework in compliance_value for framework in ['HIPAA', 'SOC2', 'CIS']):
            return CheckResult.PASSED
        
        return CheckResult.FAILED


check = RequireComplianceTags()