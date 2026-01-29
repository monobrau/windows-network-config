import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
import json
import os
import random
import sys
from datetime import datetime

def resource_path(relative_path):
    """Get absolute path to resource, works for dev and for PyInstaller"""
    try:
        # PyInstaller creates a temp folder and stores path in _MEIPASS
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")
    return os.path.join(base_path, relative_path)

class FipperdNominationGenerator:
    def __init__(self, root):
        self.root = root
        self.root.title("FIPPERD Award Nomination Generator")
        self.root.geometry("900x800")
        self.root.resizable(True, True)
        
        # Settings file path
        self.settings_file = "fipperd_settings.json"
        
        # Load real client data from extracted CSV
        try:
            teams_file = resource_path('extracted_teams.json')
            with open(teams_file, 'r') as f:
                self.default_data = json.load(f)
        except Exception as e:
            # Fallback to sample data if extraction file not found
            self.default_data = {
                "teams": {
                    "IT Support": ["Key Technical", "DataFlow Corp", "SecureNet Solutions", "TechVision Inc"],
                    "Development": ["InnovateTech", "CodeCraft Solutions", "DigitalForge", "AppMasters"],
                    "Infrastructure": ["CloudFirst", "NetworkPro", "ServerTech", "SystemCore"],
                    "Security": ["CyberGuard", "SecureBase", "ThreatShield", "SafeNet Corp"],
                    "Project Management": ["DeliveryPro", "ProjectFlow", "TaskMaster", "AgileWorks"]
                }
            }
        
        # Load settings or use defaults
        self.load_settings()
        
        # FIPPERD templates for each category
        self.fipperd_templates = {
            "Focused on the client": [
                "{name} identified a potential {issue_type} in a {project_type} that involved {technical_detail} for {client} and {action_taken}. This ensured the project stayed on track and met the deadline for {client}.",
                "{name} noticed that {client} was experiencing {problem_type} and immediately {response_action} to {solution}. Their quick thinking prevented any disruption to {client}'s operations.",
                "{name} went above and beyond when {client} needed {urgent_requirement} by {innovative_solution}. This demonstrated exceptional client focus and commitment to {client}'s success.",
                "{name} proactively reached out to {client} when they discovered {potential_issue} and {preventive_action}. This prevented a major service interruption for {client}.",
                "{name} worked closely with {client} to understand their specific {business_need} and {customized_solution}. This tailored approach resulted in {client_specific_benefit} for {client}.",
                "{name} recognized that {client} had unique {technical_requirement} and {specialized_approach}. This client-focused solution delivered {measurable_improvement} specifically for {client}."
            ],
            "Innovative": [
                "{name} developed an innovative {solution_type} for {client} when {challenge} by {creative_approach}. This {positive_outcome} and significantly improved {improvement_area} for {client}.",
                "{name} created a unique {innovation_type} that {problem_solved} for {client}. Their creative thinking resulted in {measurable_benefit} specifically benefiting {client}.",
                "{name} implemented an inventive {technical_solution} to address {client}'s {complex_challenge}. This innovative approach {success_metric} for {client}.",
                "{name} pioneered a new {methodology} that {achievement} for {client}. Their forward-thinking solution has become a model for future {client} projects.",
                "{name} designed a custom {innovative_tool} specifically for {client}'s {unique_situation}. This creative solution {innovation_outcome} and set a new standard for {client}.",
                "{name} developed a breakthrough {technical_innovation} when {client} faced {technical_obstacle}. This inventive approach {remarkable_result} for {client}."
            ],
            "Positive": [
                "{name} maintained a positive attitude when facing {difficult_situation} and {encouraging_action}. Their optimism helped the team overcome {challenge_overcome}.",
                "{name} brought exceptional energy to {project_context} by {positive_contribution}. Their enthusiasm was contagious and {team_impact}.",
                "{name} turned a potentially negative situation with {client} into a success by {positive_approach}. Their upbeat demeanor {relationship_outcome}.",
                "{name} consistently demonstrated positivity during {stressful_period} by {supportive_behavior}. This helped maintain team morale and {project_success}."
            ],
            "Precise": [
                "{name} demonstrated exceptional attention to detail when {precision_context} by {meticulous_action}. Their precision prevented {potential_error} for {client}.",
                "{name} caught a critical {error_type} in {technical_area} that could have caused {serious_consequence}. Their meticulous review saved {client} from {avoided_problem}.",
                "{name} executed {complex_task} with remarkable precision, ensuring {quality_outcome}. Their attention to detail resulted in {client_benefit}.",
                "{name} provided precise documentation for {project_element} that enabled {team_success}. Their thoroughness ensured {positive_result} for {client}."
            ],
            "Engaged and communicative": [
                "{name} facilitated excellent communication between {stakeholders} when {communication_challenge} arose. Their engagement ensured {successful_outcome} for {client}.",
                "{name} proactively communicated {important_information} to all stakeholders, preventing {potential_confusion}. Their clear communication kept the project on track for {client}.",
                "{name} engaged effectively with {client} during {challenging_discussion} and {communication_success}. Their diplomatic approach strengthened the client relationship.",
                "{name} maintained open lines of communication throughout {project_phase} by {communication_method}. This transparency resulted in {trust_building} with {client}."
            ],
            "Responsible and accountable": [
                "{name} took full responsibility when {accountability_situation} occurred and {corrective_action}. Their accountability ensured {client} experienced minimal impact.",
                "{name} demonstrated exceptional ownership of {responsibility_area} by {ownership_action}. Their reliability gave {client} complete confidence in our service delivery.",
                "{name} held themselves accountable for {project_outcome} and {improvement_action}. This responsibility led to {enhanced_result} for {client}.",
                "{name} stepped up to take responsibility for {challenging_situation} and {resolution_approach}. Their accountability turned a potential issue into a success for {client}."
            ],
            "Driven": [
                "{name} showed remarkable drive when {challenging_goal} seemed difficult to achieve by {determined_action}. Their persistence resulted in {success_outcome} for {client}.",
                "{name} demonstrated exceptional determination to {ambitious_objective} by {persistent_effort}. Their drive led to {achievement} that exceeded {client}'s expectations.",
                "{name} pursued {difficult_target} with unwavering commitment and {driven_behavior}. Their tenacity delivered {impressive_result} for {client}.",
                "{name} remained driven to find a solution when {complex_problem} threatened {client_impact}. Their determination led to {breakthrough_solution}."
            ]
        }
        
        # Variables for template filling
        self.template_variables = {
            "issue_type": ["delay", "bottleneck", "technical issue", "configuration problem", "performance concern"],
            "project_type": ["critical project", "time-sensitive deployment", "major upgrade", "system migration", "security implementation"],
            "technical_detail": ["a LetsEncrypt certificate", "SSL configuration", "DNS settings", "firewall rules", "database optimization"],
            "action_taken": ["developed an innovative contingency plan by purchasing a certificate instead", "implemented a workaround solution", "created an alternative approach", "established a backup strategy", "designed a rapid response protocol"],
            "problem_type": ["connectivity issues", "performance degradation", "security concerns", "system instability", "data synchronization problems"],
            "response_action": ["coordinated with the technical team", "mobilized resources", "implemented emergency protocols", "activated the response plan", "engaged specialist support"],
            "solution": ["resolve the issue within hours", "implement a permanent fix", "restore full functionality", "optimize system performance", "enhance security posture"],
            "urgent_requirement": ["immediate system recovery", "emergency data backup", "critical security patch", "rapid deployment", "urgent troubleshooting"],
            "innovative_solution": ["implementing a custom automation script", "creating a hybrid cloud solution", "developing a real-time monitoring system", "establishing redundant pathways", "building a failover mechanism"],
            "potential_issue": ["upcoming license expiration", "capacity limitations", "security vulnerabilities", "compatibility concerns", "performance bottlenecks"],
            "preventive_action": ["coordinated early renewal", "implemented capacity planning", "applied security patches", "tested compatibility", "optimized performance"],
            "solution_type": ["automation framework", "monitoring solution", "integration platform", "optimization tool", "security protocol"],
            "challenge": ["facing complex integration requirements", "dealing with legacy system constraints", "managing tight deadlines", "working with limited resources", "addressing scalability concerns"],
            "creative_approach": ["leveraging existing APIs in a new way", "combining multiple technologies", "implementing a phased rollout", "creating custom middleware", "developing a hybrid solution"],
            "positive_outcome": ["reduced processing time by 50%", "improved system reliability", "enhanced user experience", "strengthened security posture", "increased operational efficiency"],
            "improvement_area": ["system performance", "user satisfaction", "operational efficiency", "security compliance", "cost effectiveness"],
            "innovation_type": ["monitoring dashboard", "automation workflow", "integration solution", "optimization algorithm", "security framework"],
            "problem_solved": ["eliminated manual processes", "resolved performance issues", "improved data accuracy", "enhanced system stability", "streamlined operations"],
            "measurable_benefit": ["30% reduction in response time", "zero downtime deployment", "improved user satisfaction scores", "enhanced system reliability", "significant cost savings"],
            "technical_solution": ["load balancing configuration", "caching mechanism", "API gateway", "microservices architecture", "containerization strategy"],
            "complex_challenge": ["high-availability requirements", "data migration complexities", "integration constraints", "performance bottlenecks", "security compliance needs"],
            "success_metric": ["exceeded performance targets", "achieved 99.9% uptime", "reduced costs by 25%", "improved response times", "enhanced user experience"],
            "methodology": ["deployment strategy", "testing framework", "monitoring approach", "backup procedure", "incident response protocol"],
            "achievement": ["streamlined operations", "improved reliability", "enhanced security", "reduced complexity", "increased efficiency"],
            "difficult_situation": ["a major system outage", "tight project deadlines", "resource constraints", "technical challenges", "client concerns"],
            "encouraging_action": ["motivated the team to find solutions", "maintained focus on objectives", "facilitated collaborative problem-solving", "kept stakeholders informed", "promoted creative thinking"],
            "challenge_overcome": ["the technical obstacles", "timeline pressures", "resource limitations", "complexity issues", "integration challenges"],
            "project_context": ["a challenging migration project", "a complex integration", "a critical deployment", "an urgent troubleshooting session", "a demanding client requirement"],
            "positive_contribution": ["sharing knowledge with team members", "mentoring junior staff", "facilitating collaboration", "maintaining team spirit", "encouraging innovation"],
            "team_impact": ["improved overall productivity", "strengthened team cohesion", "enhanced problem-solving capabilities", "boosted team confidence", "fostered innovation"],
            "positive_approach": ["focusing on solutions rather than problems", "maintaining open communication", "providing regular updates", "offering alternative options", "demonstrating flexibility"],
            "relationship_outcome": ["strengthened the client partnership", "built trust and confidence", "improved communication", "enhanced collaboration", "created lasting goodwill"],
            "stressful_period": ["a critical system outage", "tight project deadlines", "complex troubleshooting", "major system upgrade", "emergency response"],
            "supportive_behavior": ["offering assistance to colleagues", "sharing expertise freely", "maintaining calm under pressure", "providing encouragement", "facilitating team communication"],
            "project_success": ["delivered on time and budget", "exceeded client expectations", "maintained high quality standards", "achieved all objectives", "strengthened team relationships"],
            "precision_context": ["reviewing system configurations", "validating data migrations", "testing security implementations", "documenting procedures", "quality assurance processes"],
            "meticulous_action": ["conducting thorough testing", "performing detailed reviews", "validating all configurations", "documenting every step", "implementing quality checks"],
            "potential_error": ["a critical configuration mistake", "data corruption", "security vulnerabilities", "system instabilities", "compliance issues"],
            "error_type": ["configuration error", "data inconsistency", "security gap", "performance issue", "compatibility problem"],
            "technical_area": ["the database configuration", "network settings", "security protocols", "system architecture", "integration points"],
            "serious_consequence": ["system downtime", "data loss", "security breach", "compliance violation", "service disruption"],
            "avoided_problem": ["potential data loss", "system instability", "security vulnerabilities", "performance degradation", "compliance issues"],
            "complex_task": ["system migration", "security implementation", "performance optimization", "integration project", "infrastructure upgrade"],
            "quality_outcome": ["zero defects in production", "seamless user experience", "optimal performance", "enhanced security", "improved reliability"],
            "client_benefit": ["increased system reliability", "improved performance", "enhanced security", "reduced operational costs", "better user experience"],
            "project_element": ["technical specifications", "implementation procedures", "testing protocols", "deployment steps", "troubleshooting guides"],
            "team_success": ["smooth project execution", "efficient knowledge transfer", "rapid problem resolution", "effective collaboration", "successful delivery"],
            "positive_result": ["project success", "enhanced capabilities", "improved processes", "better outcomes", "increased satisfaction"],
            "stakeholders": ["technical teams and management", "clients and vendors", "internal departments", "project teams", "support staff"],
            "communication_challenge": ["conflicting requirements", "technical complexity", "tight timelines", "resource constraints", "changing priorities"],
            "successful_outcome": ["aligned expectations", "clear project direction", "efficient execution", "stakeholder satisfaction", "timely delivery"],
            "important_information": ["critical system changes", "project status updates", "risk assessments", "timeline adjustments", "resource requirements"],
            "potential_confusion": ["miscommunication", "conflicting priorities", "unclear requirements", "timeline conflicts", "resource allocation issues"],
            "challenging_discussion": ["requirement negotiations", "technical reviews", "budget discussions", "timeline planning", "risk assessment"],
            "communication_success": ["achieved consensus on requirements", "clarified technical specifications", "aligned on project goals", "resolved concerns", "established clear expectations"],
            "project_phase": ["planning and design", "implementation", "testing and validation", "deployment", "post-implementation support"],
            "communication_method": ["regular status meetings", "detailed documentation", "collaborative tools", "progress dashboards", "stakeholder briefings"],
            "trust_building": ["enhanced confidence", "stronger partnerships", "improved collaboration", "better understanding", "increased satisfaction"],
            "accountability_situation": ["a system issue", "a missed deadline", "a configuration error", "a communication gap", "a process failure"],
            "corrective_action": ["immediately implemented fixes", "established preventive measures", "improved processes", "enhanced monitoring", "strengthened procedures"],
            "responsibility_area": ["system performance", "project delivery", "client satisfaction", "team coordination", "quality assurance"],
            "ownership_action": ["proactively monitoring systems", "ensuring quality standards", "maintaining clear communication", "delivering on commitments", "continuously improving processes"],
            "project_outcome": ["delivery timelines", "quality standards", "client satisfaction", "team performance", "system reliability"],
            "improvement_action": ["implemented process enhancements", "established better procedures", "improved monitoring", "strengthened quality controls", "enhanced team training"],
            "enhanced_result": ["improved performance", "better quality", "higher satisfaction", "increased reliability", "enhanced capabilities"],
            "challenging_situation": ["a critical system failure", "tight project constraints", "complex requirements", "resource limitations", "technical difficulties"],
            "resolution_approach": ["developed comprehensive solutions", "coordinated team efforts", "implemented corrective measures", "established preventive controls", "improved processes"],
            "challenging_goal": ["meeting aggressive deadlines", "achieving performance targets", "implementing complex solutions", "managing multiple priorities", "delivering exceptional quality"],
            "determined_action": ["working extended hours", "coordinating with multiple teams", "implementing creative solutions", "overcoming technical obstacles", "maintaining focus on objectives"],
            "success_outcome": ["exceeded performance targets", "delivered ahead of schedule", "achieved all objectives", "surpassed quality standards", "enhanced client satisfaction"],
            "ambitious_objective": ["optimize system performance", "implement zero-downtime deployment", "achieve full automation", "enhance security posture", "streamline operations"],
            "persistent_effort": ["continuous testing and refinement", "collaborative problem-solving", "innovative thinking", "dedicated focus", "systematic approach"],
            "achievement": ["exceptional performance improvements", "seamless system integration", "enhanced operational efficiency", "superior quality delivery", "outstanding client satisfaction"],
            "difficult_target": ["100% system uptime", "sub-second response times", "zero security incidents", "complete automation", "perfect data accuracy"],
            "driven_behavior": ["relentless problem-solving", "continuous improvement efforts", "innovative approaches", "collaborative teamwork", "persistent dedication"],
            "impressive_result": ["industry-leading performance", "exceptional reliability", "outstanding user experience", "significant cost savings", "superior quality"],
            "complex_problem": ["system integration challenges", "performance bottlenecks", "security vulnerabilities", "scalability issues", "compatibility constraints"],
            "client_impact": ["service delivery", "business operations", "user experience", "system reliability", "operational efficiency"],
            "breakthrough_solution": ["an innovative workaround", "a creative integration approach", "an optimized configuration", "a hybrid solution", "a scalable architecture"],
            "business_need": ["compliance requirements", "operational efficiency goals", "security standards", "performance objectives", "scalability demands"],
            "customized_solution": ["implemented a tailored configuration", "developed a bespoke workflow", "created a specialized integration", "designed a custom protocol", "built a personalized dashboard"],
            "client_specific_benefit": ["improved operational efficiency", "enhanced security posture", "reduced operational costs", "streamlined workflows", "increased system reliability"],
            "technical_requirement": ["high-availability needs", "specialized security protocols", "custom integration points", "unique performance criteria", "specific compliance standards"],
            "specialized_approach": ["developed a custom methodology", "implemented industry-specific protocols", "created tailored security measures", "designed specialized workflows", "built custom monitoring solutions"],
            "measurable_improvement": ["25% faster processing times", "99.9% uptime achievement", "50% reduction in support tickets", "enhanced user satisfaction scores", "significant cost savings"],
            "innovative_tool": ["monitoring dashboard", "automation script", "integration platform", "reporting system", "optimization utility"],
            "unique_situation": ["legacy system constraints", "regulatory requirements", "high-security environment", "complex integration needs", "specialized workflow demands"],
            "innovation_outcome": ["streamlined their operations", "enhanced their capabilities", "improved their efficiency", "strengthened their security", "optimized their performance"],
            "technical_innovation": ["API integration solution", "automated monitoring system", "custom security protocol", "performance optimization tool", "hybrid cloud architecture"],
            "technical_obstacle": ["integration challenges", "performance bottlenecks", "security compliance issues", "legacy system limitations", "scalability constraints"],
            "remarkable_result": ["exceeded all performance targets", "achieved seamless integration", "delivered exceptional reliability", "provided outstanding user experience", "created significant operational improvements"]
        }
        
        self.setup_ui()
    
    def get_technician_actions(self):
        """Return list of categorized technician actions with short descriptions"""
        return [
            # TROUBLESHOOTING CATEGORY
            "🔧 SSL Certificate Issue - Expiring cert detected",
            "🔧 Network Bottleneck - Performance degradation found", 
            "🔧 Security Breach Signs - Unusual login patterns detected",
            "🔧 Firewall Misconfiguration - Essential services blocked",
            "🔧 Backup Failure - Data protection at risk",
            "🔧 Outdated Software - Security vulnerabilities identified",
            "🔧 Disk Space Critical - System failure imminent",
            "🔧 Memory Leak - Application instability detected",
            "🔧 DNS Error - Email delivery affected",
            "🔧 Unauthorized Devices - Network security compromised",
            "🔧 Database Performance - User experience degraded",
            "🔧 Unusual Traffic - Network anomaly detected",
            "🔧 Permission Error - Security risk from misconfig",
            "🔧 Hard Drive Failing - Data loss prevention",
            "🔧 Email Server Issue - Communication disruption",
            "🔧 Malware Detection - Early stage infection found",
            "🔧 Switch Configuration - Network connectivity problem",
            "🔧 VPN Connectivity - Remote worker access issue",
            "🔧 Driver Conflict - System crash causing problem",
            "🔧 Antivirus Outdated - Security gap identified",
            
            # DEPLOYMENT CATEGORY  
            "🚀 Workstation Deployment - New employee setup",
            "🚀 Workstation Upgrade - Hardware replacement project",
            "🚀 Workstation Replacement - End-of-life system refresh",
            "🚀 Server Migration - Critical system upgrade",
            "🚀 Server Replacement - Hardware refresh project",
            "🚀 Server Upgrade - Performance enhancement deployment",
            "🚀 Network Device Install - Infrastructure expansion", 
            "🚀 Software Rollout - Department-wide deployment",
            "🚀 Security System Deploy - Enhanced protection implementation",
            "🚀 Backup Solution Setup - Data protection enhancement",
            "🚀 Monitoring Tools Deploy - Proactive system oversight",
            "🚀 Cloud Migration - Infrastructure modernization",
            "🚀 Firewall Upgrade - Security infrastructure improvement",
            "🚀 Wi-Fi Network Expansion - Coverage enhancement project",
            "🚀 Database Server Setup - Performance optimization deployment",
            "🚀 Patch Management Deploy - Automated update system",
            "🚀 Remote Access Setup - Work-from-home enablement",
            "🚀 Phone System Upgrade - Communication enhancement",
            "🚀 Printer Network Deploy - Office productivity improvement",
            
            # ABOVE & BEYOND CATEGORY
            "⭐ Weekend Emergency Response - Off-hours critical support",
            "⭐ Proactive System Monitoring - Preventive maintenance initiative", 
            "⭐ User Training Session - Knowledge transfer initiative",
            "⭐ Documentation Creation - Process improvement project",
            "⭐ Vendor Coordination - Complex project management",
            "⭐ After-Hours Maintenance - Minimal disruption scheduling",
            "⭐ Emergency Procurement - Rapid solution acquisition",
            "⭐ Cross-Team Collaboration - Interdepartmental support",
            "⭐ Process Optimization - Efficiency improvement initiative",
            "⭐ Mentoring Junior Staff - Knowledge sharing commitment",
            "⭐ Client Consultation - Strategic planning assistance",
            "⭐ Risk Assessment - Proactive vulnerability analysis",
            "⭐ Compliance Audit Prep - Regulatory readiness initiative",
            "⭐ Disaster Recovery Test - Business continuity validation",
            "⭐ Innovation Research - Technology evaluation project"
        ]
    
    def get_helpful_outcomes(self):
        """Return list of positive outcomes with variety"""
        return [
            # BUSINESS IMPACT OUTCOMES
            "💼 Prevented system downtime during peak business hours",
            "💼 Avoided data loss that could have cost thousands in recovery",
            "💼 Eliminated performance issues affecting daily operations", 
            "💼 Prevented email outages during critical communications",
            "💼 Avoided system crashes during important client presentations",
            "💼 Prevented bandwidth bottlenecks during peak usage",
            "💼 Eliminated daily productivity disruptions",
            "💼 Avoided business process interruptions",
            "💼 Prevented customer service disruptions",
            "💼 Eliminated workflow bottlenecks affecting efficiency",
            
            # SECURITY OUTCOMES
            "🔒 Stopped security breach before data was compromised",
            "🔒 Prevented network intrusions by unauthorized users",
            "🔒 Eliminated vulnerabilities before exploitation",
            "🔒 Stopped unauthorized access to confidential information",
            "🔒 Prevented malware spread to other systems",
            "🔒 Avoided security gaps leaving systems exposed",
            "🔒 Eliminated compliance violations preventing fines",
            "🔒 Prevented data breach affecting customer trust",
            "🔒 Stopped potential insider threat activities",
            "🔒 Avoided regulatory compliance failures",
            
            # COST SAVINGS OUTCOMES
            "💰 Saved thousands in emergency repair costs",
            "💰 Avoided expensive data recovery procedures", 
            "💰 Prevented costly hardware replacement",
            "💰 Eliminated need for emergency vendor support",
            "💰 Avoided licensing violation penalties",
            "💰 Prevented expensive downtime losses",
            "💰 Saved budget through proactive maintenance",
            "💰 Avoided costly compliance audit failures",
            "💰 Prevented expensive emergency procurement",
            "💰 Eliminated overtime costs for emergency fixes",
            
            # OPERATIONAL EXCELLENCE OUTCOMES
            "⚡ Enhanced system reliability and performance",
            "⚡ Improved the user experience and satisfaction",
            "⚡ Streamlined operations for better efficiency",
            "⚡ Strengthened disaster recovery capabilities",
            "⚡ Optimized network performance across the organization",
            "⚡ Enhanced remote work capabilities for staff",
            "⚡ Improved system monitoring and alerting",
            "⚡ Strengthened backup and recovery processes",
            "⚡ Enhanced security posture organization-wide",
            "⚡ Improved vendor relationship management",
            "⚡ Modernized infrastructure with the latest technology",
            "⚡ Increased system processing speed and capacity",
            "⚡ Extended hardware lifecycle and reliability",
            "⚡ Enhanced user productivity through improved performance",
            "⚡ Improved system scalability for future growth",
            
            # STRATEGIC OUTCOMES
            "🎯 Positioned the client for future technology growth",
            "🎯 Enhanced client's competitive advantage",
            "🎯 Improved client's reputation for reliability",
            "🎯 Strengthened client relationships through excellence",
            "🎯 Demonstrated proactive service delivery",
            "🎯 Built a foundation for digital transformation",
            "🎯 Enhanced client's operational resilience",
            "🎯 Improved client's risk management posture",
            "🎯 Strengthened client's business continuity",
            "🎯 Enhanced client's innovation capabilities"
        ]
    
    def get_work_locations(self):
        """Return list of work locations"""
        return [
            "While on-site at the client location",
            "While working from the office",
            "While working remotely",
            "During an emergency on-site visit",
            "While conducting routine maintenance on-site",
            "During a scheduled client visit",
            "While responding to an urgent call on-site",
            "During after-hours work at the office",
            "While working from home",
            "During a weekend emergency response",
            "While at the client's data center",
            "During a planned maintenance window on-site",
            "While providing remote support",
            "During an on-site consultation",
            "While working at the client's branch office",
            "During a hybrid work session",
            "While conducting training at the client site",
            "During remote troubleshooting",
            "While performing on-site diagnostics",
            "During virtual collaboration with the team"
        ]
    
    def get_mitigating_circumstances(self):
        """Return list of challenging circumstances with positive language"""
        return [
            "None - Standard conditions",
            "Extremely tight deadline requiring rapid response",
            "High-pressure situation with demanding client expectations",
            "Complex multi-stakeholder environment requiring coordination",
            "Critical system outage affecting business operations",
            "Limited resources and budget constraints",
            "Legacy system compatibility challenges",
            "Regulatory compliance deadline pressure",
            "Emergency weekend/holiday response required",
            "Multiple competing priorities and urgent requests",
            "Challenging technical environment with outdated infrastructure",
            "High-visibility project with executive attention",
            "Vendor coordination challenges across time zones",
            "Staff shortage requiring individual initiative",
            "Concurrent project deadlines creating resource conflicts",
            "Client location access restrictions and security protocols",
            "Integration complexity with multiple third-party systems",
            "Performance requirements exceeding standard specifications",
            "Budget approval delays requiring creative solutions",
            "Change management resistance requiring diplomatic approach",
            "Disaster recovery scenario with time-critical requirements",
            "Audit preparation with strict documentation requirements",
            "New technology implementation with learning curve challenges",
            "Cross-departmental coordination requiring consensus building",
            "International client with cultural and language considerations"
        ]
    
    def get_full_action_description(self, short_action):
        """Convert short action description to full detailed text"""
        action_mappings = {
            # TROUBLESHOOTING CATEGORY
            "🔧 SSL Certificate Issue - Expiring cert detected": "identified a critical SSL certificate expiration that would have caused website downtime",
            "🔧 Network Bottleneck - Performance degradation found": "discovered a network bottleneck that was significantly affecting system performance across the organization", 
            "🔧 Security Breach Signs - Unusual login patterns detected": "detected unusual login patterns indicating a potential security breach attempt",
            "🔧 Firewall Misconfiguration - Essential services blocked": "found a misconfigured Firewall rule that was blocking essential business services",
            "🔧 Backup Failure - Data protection at risk": "noticed critical backup failures that could have led to catastrophic data loss",
            "🔧 Outdated Software - Security vulnerabilities identified": "identified outdated software versions containing serious security vulnerabilities",
            "🔧 Disk Space Critical - System failure imminent": "discovered critical disk space issues before they caused complete system failures",
            "🔧 Memory Leak - Application instability detected": "detected memory leaks that were causing critical application instability",
            "🔧 DNS Error - Email delivery affected": "found DNS configuration errors that were severely affecting email delivery",
            "🔧 Unauthorized Devices - Network security compromised": "identified unauthorized devices on the network that compromised security",
            "🔧 Database Performance - User experience degraded": "discovered database performance issues that were degrading user experience",
            "🔧 Unusual Traffic - Network anomaly detected": "noticed unusual network traffic patterns indicating potential security threats",
            "🔧 Permission Error - Security risk from misconfig": "found misconfigured user permissions creating significant security risks",
            "🔧 Hard Drive Failing - Data loss prevention": "identified failing hard drives before complete failure and data loss",
            "🔧 Email Server Issue - Communication disruption": "discovered Email Server configuration problems disrupting business communications",
            "🔧 Malware Detection - Early stage infection found": "detected malware infections in their early stages before system-wide compromise",
            "🔧 Switch Configuration - Network connectivity problem": "found network switch configuration errors causing connectivity problems",
            "🔧 VPN Connectivity - Remote worker access issue": "identified VPN connectivity issues that were affecting remote worker productivity",
            "🔧 Driver Conflict - System crash causing problem": "discovered printer driver conflicts that were causing recurring system crashes",
            "🔧 Antivirus Outdated - Security gap identified": "noticed that antivirus definitions were severely outdated, creating security gaps",
            
            # DEPLOYMENT CATEGORY  
            "🚀 Workstation Deployment - New employee setup": "successfully deployed and configured new workstations for incoming employees with zero downtime",
            "🚀 Workstation Upgrade - Hardware replacement project": "expertly managed workstation hardware upgrades across multiple departments ensuring improved performance and reliability",
            "🚀 Workstation Replacement - End-of-life system refresh": "orchestrated the replacement of aging workstations with modern systems, ensuring seamless user transition and enhanced productivity",
            "🚀 Server Migration - Critical system upgrade": "expertly managed a complex Server migration project ensuring business continuity",
            "🚀 Server Replacement - Hardware refresh project": "successfully replaced critical server hardware with modern, high-performance systems ensuring enhanced reliability and capacity",
            "🚀 Server Upgrade - Performance enhancement deployment": "implemented comprehensive server upgrades including memory, storage, and processing enhancements to optimize performance",
            "🚀 Network Device Install - Infrastructure expansion": "seamlessly installed and configured new Network devices to expand infrastructure capacity", 
            "🚀 Software Rollout - Department-wide deployment": "orchestrated a department-wide software deployment with minimal user disruption",
            "🚀 Security System Deploy - Enhanced protection implementation": "implemented enhanced Security systems to strengthen the organization's protection",
            "🚀 Backup Solution Setup - Data protection enhancement": "designed and deployed a comprehensive Backup solution enhancing data protection",
            "🚀 Monitoring Tools Deploy - Proactive system oversight": "deployed advanced Monitoring tools to enable proactive system management",
            "🚀 Cloud Migration - Infrastructure modernization": "led a successful Cloud migration project modernizing the entire infrastructure",
            "🚀 Firewall Upgrade - Security infrastructure improvement": "upgraded Firewall systems significantly improving security infrastructure",
            "🚀 Wi-Fi Network Expansion - Coverage enhancement project": "expanded Wi-Fi Network coverage ensuring seamless connectivity throughout the facility",
            "🚀 Database Server Setup - Performance optimization deployment": "configured new Database Servers optimizing performance and reliability",
            "🚀 Patch Management Deploy - Automated update system": "implemented automated Patch Management systems ensuring consistent security updates",
            "🚀 Remote Access Setup - Work-from-home enablement": "established secure Remote Access solutions enabling effective work-from-home capabilities",
            "🚀 Phone System Upgrade - Communication enhancement": "upgraded Phone Systems enhancing communication capabilities organization-wide",
            "🚀 Printer Network Deploy - Office productivity improvement": "deployed Network Printer infrastructure improving office productivity and efficiency",
            
            # ABOVE & BEYOND CATEGORY
            "⭐ Weekend Emergency Response - Off-hours critical support": "responded to a critical emergency during weekend hours, ensuring minimal business impact",
            "⭐ Proactive System Monitoring - Preventive maintenance initiative": "implemented proactive system monitoring that prevented multiple potential issues", 
            "⭐ User Training Session - Knowledge transfer initiative": "conducted comprehensive user training sessions to improve technology adoption and efficiency",
            "⭐ Documentation Creation - Process improvement project": "created detailed documentation that streamlined processes and improved team efficiency",
            "⭐ Vendor Coordination - Complex project management": "coordinated with multiple vendors to ensure successful project delivery on time and budget",
            "⭐ After-Hours Maintenance - Minimal disruption scheduling": "performed critical system maintenance during off-hours to minimize business disruption",
            "⭐ Emergency Procurement - Rapid solution acquisition": "rapidly procured emergency equipment and coordinated installation to prevent extended downtime",
            "⭐ Cross-Team Collaboration - Interdepartmental support": "collaborated across multiple departments to deliver integrated solutions",
            "⭐ Process Optimization - Efficiency improvement initiative": "analyzed and optimized existing processes resulting in significant efficiency improvements",
            "⭐ Mentoring Junior Staff - Knowledge sharing commitment": "mentored junior team members, sharing expertise to build organizational capability",
            "⭐ Client Consultation - Strategic planning assistance": "provided strategic technology consultation helping the client plan for future growth",
            "⭐ Risk Assessment - Proactive vulnerability analysis": "conducted comprehensive risk assessments identifying and mitigating potential vulnerabilities",
            "⭐ Compliance Audit Prep - Regulatory readiness initiative": "prepared comprehensive compliance documentation ensuring successful regulatory audit",
            "⭐ Disaster Recovery Test - Business continuity validation": "orchestrated disaster recovery testing validating business continuity procedures",
            "⭐ Innovation Research - Technology evaluation project": "researched and evaluated innovative technologies to enhance client capabilities"
        }
        
        return action_mappings.get(short_action, short_action.lower())
    
    def get_full_outcome_description(self, short_outcome):
        """Convert short outcome description to full detailed text"""
        # Remove emoji and category prefix for cleaner text
        clean_outcome = short_outcome.split(' ', 1)[1] if ' ' in short_outcome else short_outcome
        # Don't lowercase - keep proper capitalization
        return clean_outcome
        
    def load_settings(self):
        """Load settings from file or use defaults"""
        if os.path.exists(self.settings_file):
            try:
                with open(self.settings_file, 'r') as f:
                    self.settings = json.load(f)
            except:
                self.settings = self.default_data.copy()
        else:
            self.settings = self.default_data.copy()
    
    def save_settings(self):
        """Save current settings to file"""
        try:
            with open(self.settings_file, 'w') as f:
                json.dump(self.settings, f, indent=2)
            messagebox.showinfo("Success", "Settings saved successfully!")
        except Exception as e:
            messagebox.showerror("Error", f"Failed to save settings: {str(e)}")
    
    def setup_ui(self):
        """Create the main UI"""
        # Create main frame
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(1, weight=1)
        
        # Title
        title_label = ttk.Label(main_frame, text="FIPPERD Award Nomination Generator", 
                               font=('Arial', 16, 'bold'))
        title_label.grid(row=0, column=0, columnspan=3, pady=(0, 20))
        
        # FIPPERD explanation
        fipperd_text = ("FIPPERD: Focused on the client, Innovative, Positive, Precise, "
                       "Engaged and communicative, Responsible and accountable, Driven")
        explanation_label = ttk.Label(main_frame, text=fipperd_text, font=('Arial', 10))
        explanation_label.grid(row=1, column=0, columnspan=3, pady=(0, 20))
        
        # Employee name
        ttk.Label(main_frame, text="Employee Name:").grid(row=2, column=0, sticky=tk.W, pady=5)
        self.name_var = tk.StringVar()
        name_entry = ttk.Entry(main_frame, textvariable=self.name_var, width=30)
        name_entry.grid(row=2, column=1, sticky=(tk.W, tk.E), pady=5, padx=(5, 0))
        
        # Team selection
        ttk.Label(main_frame, text="Team:").grid(row=3, column=0, sticky=tk.W, pady=5)
        self.team_var = tk.StringVar()
        self.team_combo = ttk.Combobox(main_frame, textvariable=self.team_var, 
                                      values=list(self.settings["teams"].keys()), 
                                      state="readonly", width=28)
        self.team_combo.grid(row=3, column=1, sticky=(tk.W, tk.E), pady=5, padx=(5, 0))
        self.team_combo.bind('<<ComboboxSelected>>', self.on_team_selected)
        
        # Client selection
        ttk.Label(main_frame, text="Client:").grid(row=4, column=0, sticky=tk.W, pady=5)
        self.client_var = tk.StringVar()
        self.client_combo = ttk.Combobox(main_frame, textvariable=self.client_var, 
                                        state="readonly", width=28)
        self.client_combo.grid(row=4, column=1, sticky=(tk.W, tk.E), pady=5, padx=(5, 0))
        
        # FIPPERD category selection
        ttk.Label(main_frame, text="FIPPERD Category:").grid(row=5, column=0, sticky=tk.W, pady=5)
        self.category_var = tk.StringVar()
        category_combo = ttk.Combobox(main_frame, textvariable=self.category_var,
                                     values=list(self.fipperd_templates.keys()),
                                     state="readonly", width=28)
        category_combo.grid(row=5, column=1, sticky=(tk.W, tk.E), pady=5, padx=(5, 0))
        
        # Technician action dropdown
        ttk.Label(main_frame, text="What They Did:").grid(row=6, column=0, sticky=tk.W, pady=5)
        self.action_var = tk.StringVar()
        self.action_combo = ttk.Combobox(main_frame, textvariable=self.action_var,
                                        values=self.get_technician_actions(),
                                        state="readonly", width=28)
        self.action_combo.grid(row=6, column=1, sticky=(tk.W, tk.E), pady=5, padx=(5, 0))
        
        # How it helped dropdown
        ttk.Label(main_frame, text="How It Helped:").grid(row=7, column=0, sticky=tk.W, pady=5)
        self.outcome_var = tk.StringVar()
        self.outcome_combo = ttk.Combobox(main_frame, textvariable=self.outcome_var,
                                         values=self.get_helpful_outcomes(),
                                         state="readonly", width=28)
        self.outcome_combo.grid(row=7, column=1, sticky=(tk.W, tk.E), pady=5, padx=(5, 0))
        
        # Location dropdown
        ttk.Label(main_frame, text="Location:").grid(row=8, column=0, sticky=tk.W, pady=5)
        self.location_var = tk.StringVar()
        self.location_combo = ttk.Combobox(main_frame, textvariable=self.location_var,
                                          values=self.get_work_locations(),
                                          state="readonly", width=28)
        self.location_combo.grid(row=8, column=1, sticky=(tk.W, tk.E), pady=5, padx=(5, 0))
        
        # Mitigating circumstances dropdown
        ttk.Label(main_frame, text="Challenge/Circumstance:").grid(row=9, column=0, sticky=tk.W, pady=5)
        self.circumstance_var = tk.StringVar()
        self.circumstance_combo = ttk.Combobox(main_frame, textvariable=self.circumstance_var,
                                              values=self.get_mitigating_circumstances(),
                                              state="readonly", width=28)
        self.circumstance_combo.grid(row=9, column=1, sticky=(tk.W, tk.E), pady=5, padx=(5, 0))
        
        # Buttons frame for generation options
        buttons_gen_frame = ttk.Frame(main_frame)
        buttons_gen_frame.grid(row=10, column=0, columnspan=2, pady=20)
        
        # Generate button
        generate_btn = ttk.Button(buttons_gen_frame, text="Generate Nomination", 
                                 command=self.generate_specific_nomination)
        generate_btn.grid(row=0, column=0, padx=5)
        
        # Random generation button
        random_btn = ttk.Button(buttons_gen_frame, text="Do you feel lucky, punk?", 
                               command=self.generate_random_nomination)
        random_btn.grid(row=0, column=1, padx=5)
        
        # Optional intro sentence checkbox
        self.include_intro_var = tk.BooleanVar(value=True)
        intro_check = ttk.Checkbutton(main_frame, text="Include introductory sentence", 
                                     variable=self.include_intro_var)
        intro_check.grid(row=11, column=0, columnspan=2, sticky=tk.W, pady=(10, 0))
        
        # Output text area
        ttk.Label(main_frame, text="Generated Nomination:").grid(row=12, column=0, sticky=tk.W, pady=(10, 5))
        
        self.output_text = scrolledtext.ScrolledText(main_frame, height=12, width=80, wrap=tk.WORD)
        self.output_text.grid(row=13, column=0, columnspan=3, sticky=(tk.W, tk.E, tk.N, tk.S), pady=5)
        
        # Configure text area to expand
        main_frame.rowconfigure(13, weight=1)
        
        # Buttons frame
        buttons_frame = ttk.Frame(main_frame)
        buttons_frame.grid(row=14, column=0, columnspan=3, pady=10)
        
        # Copy to clipboard button
        copy_btn = ttk.Button(buttons_frame, text="Copy to Clipboard", 
                             command=self.copy_to_clipboard)
        copy_btn.grid(row=0, column=0, padx=5)
        
        # Settings button
        settings_btn = ttk.Button(buttons_frame, text="Manage Teams/Clients", 
                                 command=self.open_settings)
        settings_btn.grid(row=0, column=1, padx=5)
        
        # Save settings button
        save_btn = ttk.Button(buttons_frame, text="Save Settings", 
                             command=self.save_settings)
        save_btn.grid(row=0, column=2, padx=5)
        
    def on_team_selected(self, event=None):
        """Update client list when team is selected"""
        team = self.team_var.get()
        if team and team in self.settings["teams"]:
            clients = self.settings["teams"][team]
            self.client_combo.configure(values=clients)
            self.client_combo['state'] = 'readonly' 
            self.client_var.set("")  # Clear previous selection
            # Force the combobox to refresh its values
            self.client_combo.event_generate('<Button-1>')
            self.client_combo.update_idletasks()
        else:
            self.client_combo.configure(values=[])
            self.client_var.set("")
    
    def generate_nomination(self):
        """Generate a FIPPERD nomination"""
        name = self.name_var.get().strip()
        team = self.team_var.get()
        client = self.client_var.get()
        category = self.category_var.get()
        
        if not all([name, team, client, category]):
            messagebox.showwarning("Missing Information", 
                                 "Please fill in all fields before generating a nomination.")
            return
        
        # Select a random template from the chosen category
        templates = self.fipperd_templates[category]
        template = random.choice(templates)
        
        # Fill in the template with random variables
        filled_template = template
        for var_name in self.template_variables:
            if f"{{{var_name}}}" in filled_template:
                replacement = random.choice(self.template_variables[var_name])
                filled_template = filled_template.replace(f"{{{var_name}}}", replacement)
        
        # Replace name and client
        filled_template = filled_template.replace("{name}", name)
        filled_template = filled_template.replace("{client}", client)
        
        # Display the result
        self.output_text.delete(1.0, tk.END)
        self.output_text.insert(tk.END, filled_template)
    
    def generate_specific_nomination(self):
        """Generate nomination using specific action and outcome dropdowns"""
        name = self.name_var.get().strip()
        team = self.team_var.get()
        client = self.client_var.get()
        category = self.category_var.get()
        action = self.action_var.get()
        outcome = self.outcome_var.get()
        location = self.location_var.get()
        circumstance = self.circumstance_var.get()
        
        # Circumstance is optional, others are required
        if not all([name, team, client, category, action, outcome, location]):
            messagebox.showwarning("Missing Information", 
                                 "Please fill in all required fields before generating a specific nomination.")
            return
        
        # Get full descriptions for action and outcome
        full_action = self.get_full_action_description(action)
        full_outcome = self.get_full_outcome_description(outcome)
        fipperd_connection = self.get_fipperd_connection(category)
        
        # Build circumstance text if not "None"
        circumstance_text = ""
        if circumstance and not circumstance.startswith("None"):
            # Add proper article (a/an) for better grammar
            circumstance_lower = circumstance.lower()
            if circumstance_lower.startswith(('a ', 'an ', 'the ')):
                # Already has article
                circumstance_text = f" despite {circumstance_lower},"
            elif circumstance_lower.startswith(('extremely', 'high-', 'complex', 'critical', 'limited', 'legacy', 'regulatory', 'emergency', 'multiple', 'challenging', 'vendor', 'staff', 'concurrent', 'client', 'integration', 'performance', 'budget', 'change', 'disaster', 'audit', 'new', 'cross-', 'international')):
                # Add "a" for singular circumstances that need it
                circumstance_text = f" despite a {circumstance_lower},"
            else:
                # For plural or other cases, no article needed
                circumstance_text = f" despite {circumstance_lower},"
        
        # Build the nomination with location and optional circumstance
        nomination_body = f"{location},{circumstance_text} {name} {full_action} for {client}. {fipperd_connection} this {full_outcome.lower()}, demonstrating {name}'s commitment to {client}'s success and exemplifying the {category.lower()} value of FIPPERD."
        
        # Add optional intro sentence
        if self.include_intro_var.get():
            intro = self.get_intro_sentence(name)
            nomination = f"{intro}\n\n{nomination_body}"
        else:
            nomination = nomination_body
        
        # Display the result
        self.output_text.delete(1.0, tk.END)
        self.output_text.insert(tk.END, nomination)
    
    def generate_random_nomination(self):
        """Generate completely random nomination with just name, team, and client"""
        name = self.name_var.get().strip()
        team = self.team_var.get()
        client = self.client_var.get()
        
        if not all([name, team, client]):
            messagebox.showwarning("Missing Information", 
                                 "Please fill in Name, Team, and Client before feeling lucky!")
            return
        
        # Randomly select everything else
        category = random.choice(list(self.fipperd_templates.keys()))
        action = random.choice(self.get_technician_actions())
        outcome = random.choice(self.get_helpful_outcomes())
        location = random.choice(self.get_work_locations())
        circumstance = random.choice(self.get_mitigating_circumstances())
        
        # Update the dropdowns to show what was selected
        self.category_var.set(category)
        self.action_var.set(action)
        self.outcome_var.set(outcome)
        self.location_var.set(location)
        self.circumstance_var.set(circumstance)
        
        # Get full descriptions for action and outcome
        full_action = self.get_full_action_description(action)
        full_outcome = self.get_full_outcome_description(outcome)
        fipperd_connection = self.get_fipperd_connection(category)
        
        # Build circumstance text if not "None"
        circumstance_text = ""
        if circumstance and not circumstance.startswith("None"):
            # Add proper article (a/an) for better grammar
            circumstance_lower = circumstance.lower()
            if circumstance_lower.startswith(('a ', 'an ', 'the ')):
                # Already has article
                circumstance_text = f" despite {circumstance_lower},"
            elif circumstance_lower.startswith(('extremely', 'high-', 'complex', 'critical', 'limited', 'legacy', 'regulatory', 'emergency', 'multiple', 'challenging', 'vendor', 'staff', 'concurrent', 'client', 'integration', 'performance', 'budget', 'change', 'disaster', 'audit', 'new', 'cross-', 'international')):
                # Add "a" for singular circumstances that need it
                circumstance_text = f" despite a {circumstance_lower},"
            else:
                # For plural or other cases, no article needed
                circumstance_text = f" despite {circumstance_lower},"
        
        # Build the nomination with location and optional circumstance
        nomination_body = f"{location},{circumstance_text} {name} {full_action} for {client}. {fipperd_connection} this {full_outcome.lower()}, demonstrating {name}'s commitment to {client}'s success and exemplifying the {category.lower()} value of FIPPERD."
        
        # Add optional intro sentence
        if self.include_intro_var.get():
            intro = self.get_intro_sentence(name)
            nomination = f"{intro}\n\n{nomination_body}"
        else:
            nomination = nomination_body
        
        # Display the result
        self.output_text.delete(1.0, tk.END)
        self.output_text.insert(tk.END, nomination)
    
    def get_fipperd_connection(self, category):
        """Get a connecting sentence that relates the action to the FIPPERD value"""
        connections = {
            "Focused on the client": "By staying focused on the client's needs,",
            "Innovative": "Through innovative thinking and creative problem-solving,",
            "Positive": "With a positive attitude and proactive approach,",
            "Precise": "Using precise attention to detail and thorough analysis,",
            "Engaged and communicative": "By maintaining clear communication and staying engaged,",
            "Responsible and accountable": "Taking full responsibility and being accountable for the outcome,",
            "Driven": "With determination and a driven approach to excellence,"
        }
        return connections.get(category, "Through professional excellence,")
    
    def get_intro_sentence(self, name):
        """Generate a varied introductory sentence"""
        intros = [
            f"I would like to nominate {name} for a FIPPERD award.",
            f"I am pleased to nominate {name} for FIPPERD recognition.",
            f"I wish to submit {name} for consideration for a FIPPERD award.",
            f"It is my pleasure to nominate {name} for a FIPPERD award.",
            f"I would like to put forward {name} for a FIPPERD award.",
            f"I am honored to nominate {name} for recognition with a FIPPERD award.",
            f"I hereby nominate {name} for a FIPPERD award.",
            f"I enthusiastically nominate {name} for a FIPPERD award.",
            f"I respectfully submit {name} for a FIPPERD award.",
            f"I am delighted to nominate {name} for a FIPPERD award.",
            f"I would like to recommend {name} for a FIPPERD award.",
            f"I am proud to nominate {name} for FIPPERD recognition.",
            f"I wish to formally nominate {name} for a FIPPERD award.",
            f"I am excited to nominate {name} for a FIPPERD award.",
            f"I would like to submit {name}'s name for a FIPPERD award.",
            f"I am writing to nominate {name} for a FIPPERD award.",
            f"I have the pleasure of nominating {name} for a FIPPERD award.",
            f"I would like to propose {name} for a FIPPERD award.",
            f"I am happy to nominate {name} for recognition with a FIPPERD award.",
            f"I respectfully nominate {name} for a FIPPERD award."
        ]
        return random.choice(intros)
        
    def copy_to_clipboard(self):
        """Copy the generated nomination to clipboard"""
        content = self.output_text.get(1.0, tk.END).strip()
        if content:
            self.root.clipboard_clear()
            self.root.clipboard_append(content)
            messagebox.showinfo("Copied", "Nomination copied to clipboard!")
        else:
            messagebox.showwarning("No Content", "No nomination to copy. Please generate one first.")
    
    def open_settings(self):
        """Open settings window for managing teams and clients"""
        settings_window = tk.Toplevel(self.root)
        settings_window.title("Manage Teams and Clients")
        settings_window.geometry("600x500")
        settings_window.grab_set()  # Make it modal
        
        # Create notebook for tabs
        notebook = ttk.Notebook(settings_window)
        notebook.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Teams tab
        teams_frame = ttk.Frame(notebook)
        notebook.add(teams_frame, text="Teams")
        
        # Teams listbox
        ttk.Label(teams_frame, text="Teams:").pack(anchor=tk.W, pady=(10, 5))
        
        teams_list_frame = ttk.Frame(teams_frame)
        teams_list_frame.pack(fill=tk.BOTH, expand=True, padx=10)
        
        self.teams_listbox = tk.Listbox(teams_list_frame)
        teams_scrollbar = ttk.Scrollbar(teams_list_frame, orient=tk.VERTICAL, command=self.teams_listbox.yview)
        self.teams_listbox.configure(yscrollcommand=teams_scrollbar.set)
        
        self.teams_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        teams_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Team buttons
        team_buttons_frame = ttk.Frame(teams_frame)
        team_buttons_frame.pack(pady=10)
        
        ttk.Button(team_buttons_frame, text="Add Team", command=self.add_team).pack(side=tk.LEFT, padx=5)
        ttk.Button(team_buttons_frame, text="Remove Team", command=self.remove_team).pack(side=tk.LEFT, padx=5)
        
        # Clients tab
        clients_frame = ttk.Frame(notebook)
        notebook.add(clients_frame, text="Clients")
        
        # Team selection for clients
        ttk.Label(clients_frame, text="Select Team:").pack(anchor=tk.W, pady=(10, 5))
        self.settings_team_var = tk.StringVar()
        settings_team_combo = ttk.Combobox(clients_frame, textvariable=self.settings_team_var,
                                         values=list(self.settings["teams"].keys()),
                                         state="readonly")
        settings_team_combo.pack(fill=tk.X, padx=10, pady=5)
        settings_team_combo.bind('<<ComboboxSelected>>', self.on_settings_team_selected)
        
        # Clients listbox
        ttk.Label(clients_frame, text="Clients:").pack(anchor=tk.W, pady=(10, 5))
        
        clients_list_frame = ttk.Frame(clients_frame)
        clients_list_frame.pack(fill=tk.BOTH, expand=True, padx=10)
        
        self.clients_listbox = tk.Listbox(clients_list_frame)
        clients_scrollbar = ttk.Scrollbar(clients_list_frame, orient=tk.VERTICAL, command=self.clients_listbox.yview)
        self.clients_listbox.configure(yscrollcommand=clients_scrollbar.set)
        
        self.clients_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        clients_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        
        # Client buttons
        client_buttons_frame = ttk.Frame(clients_frame)
        client_buttons_frame.pack(pady=10)
        
        ttk.Button(client_buttons_frame, text="Add Client", command=self.add_client).pack(side=tk.LEFT, padx=5)
        ttk.Button(client_buttons_frame, text="Remove Client", command=self.remove_client).pack(side=tk.LEFT, padx=5)
        
        # Close button
        ttk.Button(settings_window, text="Close", command=settings_window.destroy).pack(pady=10)
        
        # Populate the lists
        self.refresh_teams_list()
        
    def refresh_teams_list(self):
        """Refresh the teams listbox"""
        self.teams_listbox.delete(0, tk.END)
        for team in self.settings["teams"].keys():
            self.teams_listbox.insert(tk.END, team)
    
    def refresh_clients_list(self):
        """Refresh the clients listbox for selected team"""
        self.clients_listbox.delete(0, tk.END)
        team = self.settings_team_var.get()
        if team and team in self.settings["teams"]:
            for client in self.settings["teams"][team]:
                self.clients_listbox.insert(tk.END, client)
    
    def on_settings_team_selected(self, event=None):
        """Handle team selection in settings"""
        self.refresh_clients_list()
    
    def add_team(self):
        """Add a new team"""
        team_name = tk.simpledialog.askstring("Add Team", "Enter team name:")
        if team_name and team_name.strip():
            team_name = team_name.strip()
            if team_name not in self.settings["teams"]:
                self.settings["teams"][team_name] = []
                self.refresh_teams_list()
                # Update main window combo
                self.team_combo['values'] = list(self.settings["teams"].keys())
            else:
                messagebox.showwarning("Duplicate", "Team already exists!")
    
    def remove_team(self):
        """Remove selected team"""
        selection = self.teams_listbox.curselection()
        if selection:
            team_name = self.teams_listbox.get(selection[0])
            if messagebox.askyesno("Confirm", f"Remove team '{team_name}' and all its clients?"):
                del self.settings["teams"][team_name]
                self.refresh_teams_list()
                # Update main window combo
                self.team_combo['values'] = list(self.settings["teams"].keys())
                # Clear selection if removed team was selected
                if self.team_var.get() == team_name:
                    self.team_var.set("")
                    self.client_var.set("")
                    self.client_combo['values'] = []
        else:
            messagebox.showwarning("No Selection", "Please select a team to remove.")
    
    def add_client(self):
        """Add a new client to selected team"""
        team = self.settings_team_var.get()
        if not team:
            messagebox.showwarning("No Team", "Please select a team first.")
            return
        
        client_name = tk.simpledialog.askstring("Add Client", f"Enter client name for team '{team}':")
        if client_name and client_name.strip():
            client_name = client_name.strip()
            if client_name not in self.settings["teams"][team]:
                self.settings["teams"][team].append(client_name)
                self.refresh_clients_list()
                # Update main window if same team is selected
                if self.team_var.get() == team:
                    self.client_combo['values'] = self.settings["teams"][team]
            else:
                messagebox.showwarning("Duplicate", "Client already exists in this team!")
    
    def remove_client(self):
        """Remove selected client"""
        team = self.settings_team_var.get()
        if not team:
            messagebox.showwarning("No Team", "Please select a team first.")
            return
        
        selection = self.clients_listbox.curselection()
        if selection:
            client_name = self.clients_listbox.get(selection[0])
            if messagebox.askyesno("Confirm", f"Remove client '{client_name}' from team '{team}'?"):
                self.settings["teams"][team].remove(client_name)
                self.refresh_clients_list()
                # Update main window if same team is selected
                if self.team_var.get() == team:
                    self.client_combo['values'] = self.settings["teams"][team]
                    # Clear client selection if removed client was selected
                    if self.client_var.get() == client_name:
                        self.client_var.set("")
        else:
            messagebox.showwarning("No Selection", "Please select a client to remove.")

# Import required modules for dialog
import tkinter.simpledialog

def main():
    root = tk.Tk()
    app = FipperdNominationGenerator(root)
    root.mainloop()

if __name__ == "__main__":
    main()
