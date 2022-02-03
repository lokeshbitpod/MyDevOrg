public with sharing abstract class AWS {
    //  Post initialization logic (after constructor, before call)
    protected abstract void init();
    //dfdfsdf
    //  XML Node utility methods that will help read elements
    public static Boolean getChildNodeBoolean(Dom.XmlNode node, String ns, String name) {
        try {
            return Boolean.valueOf(node.getChildElement(name, ns).getText());
        } catch(Exception e) {
            return null;
        }
    }
    
    public static DateTime getChildNodeDateTime(Dom.XmlNode node, String ns, String name) {
        try {
            return (DateTime)JSON.deserialize(node.getChildElement(name, ns).getText(), DateTime.class);
        } catch(Exception e) {
            return null;
        }
    }
    
    public static Integer getChildNodeInteger(Dom.XmlNode node, String ns, String name) {
        try {
            return Integer.valueOf(node.getChildElement(name, ns).getText());
        } catch(Exception e) {
            return null;
        }
    }
    
    public static String getChildNodeText(Dom.XmlNode node, String ns, String name) {
        try {
            return node.getChildElement(name, ns).getText();
        } catch(Exception e) {
            return null;
        }
    }
    
    //  Turns an Amazon exception into something we can present to the user/catch
    public class ServiceException extends Exception {
        public String Code, Message, Resource, RequestId;
    
        public ServiceException(Dom.XmlNode node) {
            String ns = node.getNamespace();
            Code = getChildNodeText(node, ns, 'Code');
            Message = getChildNodeText(node, ns, 'Message');
            Resource = getChildNodeText(node, ns, 'Resource');
            RequestId = getChildNodeText(node, ns, 'RequestId');
        }
        
        public String toString() {
            return JSON.serialize(this);
        }
    }
    
    //  Things we need to know about the service. Set these values in init()
    protected String host, region, service, resource, accessKey, payloadSha256, filter,contentType, secretKey, orgid;
    protected Url endpoint;
    protected HttpMethod method;
    protected Blob payload;
    protected String payloadString;
    //  Not used externally, so we hide these values
    Blob signingKey;
    DateTime requestTime;
    Map<String, String> queryParams, headerParams;

    //  Make sure we can't misspell methods
    public enum HttpMethod { XGET, XPUT, XHEAD, XOPTIONS, XDELETE, XPOST, XPATCH }

    //  Add a header
    protected void setHeader(String key, String value) {
        headerParams.put(key.toLowerCase(), value);
    }

    //  Add a query param
    protected void setQueryParam(String key, String value) {
        queryParams.put(key, uriEncode(value));
    }

    //  Call this constructor with super() in subclasses
    protected AWS() {
        requestTime = DateTime.now();
        queryParams = new Map<String, String>();
        headerParams = new Map<String, String>();
        //payloadString = Blob.valueOf('');
        payload = null;
        payloadString = '';
    }
    
    //  Create a canonical query string (used during signing)
    String createCanonicalQueryString() {
        String[] results = new String[0], keys = new List<String>(queryParams.keySet());
        keys.sort();
        for(String key: keys) {
            results.add(key+'='+queryParams.get(key));
        }
        return String.join(results, '&');
    }

    //  Create the canonical headers (used for signing)
    String createCanonicalHeaders(String[] keys) {
        keys.addAll(headerParams.keySet());
        keys.sort();
        String[] results = new String[0];
        for(String key: keys) {
            results.add(key+':'+headerParams.get(key));
        }
        return String.join(results, '\n')+'\n';
    }

    //  Create the entire canonical request
    String createCanonicalRequest(String[] headerKeys) {    
        
        return String.join(
            new String[] {
                method.name().removeStart('X'),         //  METHOD
                new Url(endPoint, resource).getPath(),  //  RESOURCE                        
                createCanonicalQueryString(),           //  CANONICAL QUERY STRING
                createCanonicalHeaders(headerKeys),     //  CANONICAL HEADERS
                String.join(headerKeys, ';'),           //  SIGNED HEADERS
                payloadSha256                           //  SHA256 PAYLOAD
            },
            '\n'
        );
    }
    
    //  We have to replace ~ and " " correctly, or we'll break AWS on those two characters
    protected string uriEncode(String value) {
        return value==null? null: EncodingUtil.urlEncode(value, 'utf-8').replaceAll('%7E','~').replaceAll('\\+','%20');
    }
    
    //  Create the entire string to sign
    String createStringToSign(String[] signedHeaders) {
        String result = createCanonicalRequest(signedHeaders);
        return String.join(
            new String[] {
                'AWS4-HMAC-SHA256',
                headerParams.get('x-amz-date'),
                String.join(new String[] { requestTime.formatGMT('YYYYMMdd'), region, service, 'aws4_request' },'/'),
                EncodingUtil.convertToHex(Crypto.generateDigest('sha256', Blob.valueof(result)))
            },
            '\n'
        );
    }
    
    //  Create our signing key
    protected void createSigningKey(String secretKey) {
        signingKey = Crypto.generateMac('hmacSHA256', Blob.valueOf('aws4_request'),
            Crypto.generateMac('hmacSHA256', Blob.valueOf(service),
                Crypto.generateMac('hmacSHA256', Blob.valueOf(region),
                    Crypto.generateMac('hmacSHA256', Blob.valueOf(requestTime.formatGMT('YYYYMMdd')), Blob.valueOf('AWS4'+secretKey))
                )
            )
        );
    }
    
    //  Create all of the bits and pieces using all utility functions above
    HttpRequest createRequest() {
        init();
        if(payload == null) 
            payload = null;            
        
        if(payloadString == null)
            payloadString = '';         
      
        if(payloadString != null)
            payloadSha256 = EncodingUtil.convertToHex(Crypto.generateDigest('sha-256', Blob.valueOf(payloadString)));
        if(payload != null)
            payloadSha256 = EncodingUtil.convertToHex(Crypto.generateDigest('sha-256', payload));
          
        setHeader('x-amz-content-sha256', payloadSha256);
        setHeader('x-amz-date', requestTime.formatGMT('YYYYMMdd\'T\'HHmmss\'Z\''));
        if(orgid != null && orgid != '')
            setHeader('x-org-id', orgid); // added this line for tenantization or org id
        if(host == null) {
            host = endpoint.getHost();
        }
        setHeader('host', host);
       // setHeader('x-debug', '1');
        HttpRequest request = new HttpRequest();
        request.setMethod(method.name().removeStart('X'));
        if(payload != null) {
            if(resource.contains('Attachment')){
                request.setBodyAsBlob(payload);
            }
        }
        if(payloadString != '' && payloadString != null) {
            request.setBody(payloadString);
        }
        String finalEndpoint = new Url(endpoint, resource).toExternalForm(); 
        String queryString = createCanonicalQueryString();
              
        if(String.isNotBlank(queryString)) {
            finalEndpoint += '?'+queryString;
        }
     
        request.setEndpoint(finalEndpoint);
        for(String key: headerParams.keySet()) {
            request.setHeader(key, headerParams.get(key));
        }
       
         request.setHeader( 'Content-Type', 'application/x-www-form-urlencoded' );  // added this new line      
     
        request.setHeader( 'Content-Type',contentType);  
        request.setTimeout(90000); 
            
        String[] headerKeys = new String[0];
        String stringToSign = createStringToSign(headerKeys);
        request.setHeader(
            'Authorization', 
            String.format(
                'AWS4-HMAC-SHA256 Credential={0}, SignedHeaders={1}, Signature={2}',
                new String[] {
                    String.join(new String[] { accessKey, requestTime.formatGMT('YYYYMMdd'), region, service, 'aws4_request' },'/'),
                    String.join(headerKeys,';'), EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', Blob.valueOf(stringToSign), signingKey))}
            )
        );
        return request;
    }
    
    //  Actually perform the request, and throw exception if response code is not valid
    protected HttpResponse sendRequest(Set<Integer> validCodes) {
        HttpResponse response;
        try{
             response = new Http().send(createRequest());
        }
        catch(exception e){
            system.debug('==send request==exception=');
        }
        if(!validCodes.contains(response.getStatusCode())) {
            throw new ServiceException(response.getBodyDocument().getRootElement());
        }
        return response;
    }
    
    //  Same as above, but assume that only 200 is valid
    //  This method exists because most of the time, 200 is what we expect
    protected HttpResponse sendRequest() {
        return sendRequest(new Set<Integer> { 200,204 });
    }
}