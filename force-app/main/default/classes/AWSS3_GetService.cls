public with sharing class AWSS3_GetService extends AWS {
    public static String APP_URL;
    public static String ACCESS_KEY;
    public static String SECRET_KEY;
    
    public override void init() {       
        region      = 'us-east-1';
        service     = 's3';          
        createSigningKey(secretKey);               
   }
   
    public void setConfiguration(String endpoint_url,String resource_url, String method_name, string filter_data, string content_type){
        Bitpod_Credentials__c bitpodConfigObj = UtilityClass.getBitpodCredentials();
        if(String.isBlank(APP_URL) && bitpodConfigObj!=null){        
            
            accessKey       = bitpodConfigObj.Access_Key__c;  
            secretKey       = bitpodConfigObj.Secret_Key__c;  
        }    
        else{        
            endpoint_url    = APP_URL;
            accessKey       = ACCESS_KEY;
            secretKey       = SECRET_KEY;
        }
        resource    = resource_url ;
        contentType = content_type;
        endpoint    = new Url(endpoint_url);
        method      = getHttpRequestMethod(method_name);
        if(String.isNotBlank(filter_data)){
            if(method_name == 'GET'){
                setQueryParam('filter',filter_data);
            }
            else{
                setQueryParam('where',filter_data);
            }
        }
    }
    public HttpResponse getBucketswithBlob(String endpoint_url,String resource_url, String method_name, Blob requestBodyForPost, string filter_data, string content_type ) {      
        setConfiguration(endpoint_url,resource_url, method_name, filter_data, content_type);        
        payload = requestBodyForPost ;              
        HttpResponse response = sendRequest();
        String[] results = new String[0];     
        return response;      
    }
        
    public HttpResponse getBuckets(String endpoint_url,String resource_url, String method_name, string requestBodyForPost, string filter_data, string content_type ) {      
        setConfiguration(endpoint_url,resource_url, method_name, filter_data, content_type);          
        payloadString = requestBodyForPost ;              
        HttpResponse response = sendRequest();
        String[] results = new String[0];     
        return response;      
    }
    private static HttpMethod getHttpRequestMethod(String method_name){
        HttpMethod method;
        switch on method_name {
            when 'GET' {
                method = HttpMethod.XGET;
            }
            when 'POST' {
                method = HttpMethod.XPOST;
            }
            when 'PUT' {
                method = HttpMethod.XPUT;
            }
            when 'DELETE' {
                method = HttpMethod.XDELETE;
            }
            when 'PATCH' {
                method = HttpMethod.XPATCH;
            }
            when else {
                method = null;
            }
        }
        return method;
    }
}