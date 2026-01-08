"""
Custom Checkov Policies - Multi-Cloud

This package contains custom compliance checks that apply across AWS, Azure, and GCP.

Policies:
- CKV_CUSTOM_1: Enforce naming convention ({cluster_name}-{environment}-*)
- CKV_CUSTOM_2: Require Compliance tag (HIPAA, SOC2, or CIS)

Usage:
    checkov -d <path> --external-checks-dir policies/checkov

Author: Terraform Modules Team
License: MIT
"""

__version__ = "1.0.0"
__all__ = ["EnforceNamingConvention", "RequireComplianceTags"]