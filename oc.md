# Debugging Unreachable Route in OpenShift

## Task Description

When a route is not reachable, the issue can stem from several components in the OpenShift architecture such as route
configuration, service configuration, pod status, DNS resolution, or network policies. Below is a step-by-step guide to
debug the issue.

## Steps and Commands to Debug the Issue

| Step | Task Description                             | Command                                                                                     | Points to Verify                                                                                                                                                                                                             |
|------|----------------------------------------------|---------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 1    | **Verify Route Configuration**               | `oc describe route <route-name>`                                                            | - Ensure the **Host/Port** and **Service** are correct. <br> - Check **TLS** and **termination settings** if configured. <br> - Verify **path** settings if used. <br> - Check the **IngressController** handling the route. |
| 2    | **Verify Service Configuration**             | `oc describe svc <service-name>`                                                            | - Ensure the service is correctly linked to the route. <br> - Verify the service **port** and **selectors** are correct. <br> - Check if **endpoints** are healthy and the service targets the right pods.                   |
| 3    | **Check Pod Status**                         | `oc get pods` <br> `oc describe pod <pod-name>`                                             | - Ensure pods are in **Running** state. <br> - Verify pod **logs** for any errors (e.g., crashes, application issues). <br> - Ensure that pods are correctly labelled and match the service selectors.                       |
| 4    | **Check DNS Resolution**                     | `oc exec <pod-name> -- nslookup <route-name>`                                               | - Ensure DNS resolves to the correct IP. <br> - Verify the route's DNS name is resolving within the cluster.                                                                                                                 |
| 5    | **Test Connectivity**                        | `oc exec <pod-name> -- curl -v <route-name>` <br> `oc exec <pod-name> -- wget <route-name>` | - Check for **connection errors** or timeouts. <br> - Ensure the route is accessible from the pod. <br> - Check if the server is responding with the correct status code (e.g., 200 OK).                                     |
| 6    | **Check Router Logs**                        | `oc logs -n openshift-ingress <router-pod-name>`                                            | - Review logs for **error messages** related to route handling, traffic, or timeouts. <br> - Ensure the router is correctly processing the route.                                                                            |
| 7    | **Check Network Policies**                   | `oc get networkpolicy` <br> `oc describe networkpolicy <policy-name>`                       | - Ensure **Network Policies** are not blocking traffic between pods and the route. <br> - Check if there are any **egress or ingress restrictions** preventing access.                                                       |
| 8    | **Check Firewall or Load Balancer Settings** | No specific command. Check with network admin                                               | - Ensure there are no **firewall rules** or **load balancer misconfigurations** blocking access to the route. <br> - Verify **external DNS** settings are correct if accessing from outside the cluster.                     |
| 9    | **Check OpenShift Router External IP/DNS**   | `oc get svc -n openshift-ingress`                                                           | - Verify the **external IP** or **DNS** for the OpenShift router is correct. <br> - Ensure that external clients are correctly routing to this IP.                                                                           |

## Additional Debugging Tips

- **Verify Route via Browser**: If the route is external, try accessing it via a browser and see if any error messages (
  e.g., certificate warnings, timeouts) appear.
- **Check Certificate Issues**: Ensure the route’s certificate is valid, especially if using HTTPS. Inspect
  the `tls.crt` and `tls.key` for valid DNS names and expiration dates.
- **Check Resource Limits**: Ensure the application pods are not running out of resources (CPU, memory) which could
  cause connectivity issues or pod crashes.

---

By following this structured debugging approach, you should be able to identify and resolve most issues related to
unreachable routes in OpenShift.

