# Write-up Template

### Analyze, choose, and justify the appropriate resource option for deploying the app.

- The CMS app size should be under the limit size of AppService
- No need for dedicated servers
- So App service is prefered due to costs and time consumption of VMs 



### Assess app changes that would change your decision.

As our app cannot well horizontally scale, if our CMS become really used a lot, it could be a good idea to switch to VMs 