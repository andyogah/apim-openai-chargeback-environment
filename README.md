## Revisions/Changes To Scope
<table>
    <thead>
      <tr>
        <th>Version #</th>
        <th>Date</th>
        <th>Updated by</th>
        <th>Reason for update</th>
        <th>Status</th>
      </tr>
    </thead>
    <tbody>
        <tr>
            <td>1.0</td>
            <td>03/15/2025</td>
            <td><code>A. Ogah</code></td>
            <td><code>Initial version</code></td>
            <td><code>In progress</code></td>
        </tr>        
    </tbody>
  </table>
<br /><br />


## 1.1 Overview

Primarily, this development tries to solve the ephemeral and scalability challenges associated with  
existing API Management (APIM) chargeback implementation for OpenAI services. Amongst other 
things it will also incrementally address all other non-functional requirements that may 
arise based of existing and future use cases or needs. This is intended to be a full solution, 
and not just APIM policies, in that it comes self-contained with supporting Azure resources to 
to meet aforementioned needs. Consideration was not given to deployment to specific networks and 
network security groups (NSGs) as those should be specified as part of an overall enterprise 
architectural landscape. However, this solution can readily plug into any existing enterprise AI architecture
by just specifying networking and network security parameters in the existing IaC.  
<br /><br />




## 1.2 Requirements

1. API Management Development Environment
2. API Management Instance
3. AI Chatbot 

<br /><br />


## 1.3  Problem Statement

1. APIM's Diagnostic Logs has a maximum log capture limit of 8192 bytes for Log analytics Workspaces at 
a time. Anything larger than that will be truncated. This applies to most other Azure resources. 
But DOI needs a solution that can handle much larger payloads
2. DOI also does not want to persist logs and data for security and privacy concerns. And even if there 
is any of such, there should be flexibility as to how long this should be held for.

These requirements are mostly related to data size and how it is stored. Other concerns are:
 - The solution should be able to handle streaming and batch data
 - The solution should be able to handle variety of natural language data input or format
 - The solution should have some form of data veracity baked in
 - The solution should be able be to provide some data chargeback insight value

 All other concerns are related to non-function requirements as follows:
 1. Cost - little or no expense
 2. Highly maintainable
 3. Highly reproducible
 4. Automated workflow and processes
<br /><br />

## 1.4 Existing Implementation and Current System

## 1.5 Pre-analysis Notes
<br /><br />

## 2.1 Architecture Design

Resources uses for this implementation are thus:
1. Azure API Management instance 
2. Function App 
3. Azure Cache for Redis 
3. Key Vault (optional) 
4. Log Analytics Workspace (optional)
5. and other related resources.
<br /><br />


## 2.2 Development Approach

## 2.3 Unit Testing
example of what the chargeback table will look like 

![Example of chargeback table](app/backend/example-log-chargeback.png)
## 2.4 Navigation

## 2.5 Technical Details

## Deployment Notes



TO BE CONTINUED.





