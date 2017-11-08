
## jsonviewer ##

http://jsonviewer.stack.hu/

restful

2、与GET不同的是，PUT请求是向服务器端发送数据的，从而改变信息，该请求就像数据库的update操作一样，用来修改数据的内容，但是不会增加数据的种类等，也就是说无论进行多少次PUT操作，其结果并没有不同。

3、POST请求同PUT请求类似，都是向服务器端发送数据的，但是该请求会改变数据的种类等资源，就像数据库的insert操作一样，会创建新的内容。几乎目前所有的提交操作都是用POST请求的。

4、DELETE请求顾名思义，就是用来删除某一个资源的，该请求就像数据库的delete操作。

就像前面所讲的一样，既然PUT和POST操作都是向服务器端发送数据的，那么两者有什么区别呢。。。POST主要作用在一个集合资源之上的（url），而PUT主要作用在一个具体资源之上的（url/xxx），通俗一下讲就是，如URL可以在客户端确定，那么可使用PUT，否则用POST。

综上所述，我们可理解为以下：
1、POST    /url      创建  
2、DELETE  /url/xxx  删除  
3、PUT     /url/xxx  更新
4、GET     /url/xxx  查看


以15言TopicAPI为例，我们就会对各请求一目了然：

使用 post 请求创建主题
使用 put 请求修改主题
使用 get 请求获取内容
使用 delete 请求删除主题


POST is most-often utilized to create new resources. In particular, it's used to create subordinate resources. That is, subordinate to some other (e.g. parent) resource. In other words, when creating a new resource, POST to the parent and the service takes care of associating the new resource with the parent, assigning an ID (new resource URI), etc. On successful creation, return HTTP status 201, returning a Location header with a link to the newly-created resource with the 201 HTTP status.

GET method is used to read (or retrieve) a representation of a resource. In the “happy” (or non-error) path, GET returns a representation in XML or JSON and an HTTP response code of 200 (OK). In an error case, it most often returns a 404 (NOT FOUND) or 400 (BAD REQUEST).According to the design of the HTTP specification, GET (along with HEAD) requests are used only to read data and not change it.

PUT is most-often utilized for update capabilities, PUT-ing to a known resource URI with the request body containing the newly-updated representation of the original resource.However, PUT can also be used to create a resource in the case where the resource ID is chosen by the client instead of by the server. In other words, if the PUT is to a URI that contains the value of a non-existent resource ID

PATCH is used for modify capabilities. The PATCH request only needs to contain the changes to the resource, not the complete resource.This resembles PUT, but the body contains a set of instructions describing how a resource currently residing on the server should be modified to produce a new version. This means that the PATCH body should not just be a modified part of the resource, but in some kind of patch language like JSON Patch or XML Patch.

DELETE is used to delete a resource identified by a URI.HTTP-spec-wise, DELETE operations are idempotent. If you DELETE a resource, it's removed On successful deletion, return HTTP status 200 (OK) along with a response body.

OPTIONS returns available HTTP methods and other options

HEAD Retrieve all resources in a collection (header only) i.e. The HEAD method asks for a response identical to that of a GET request, but without the response body. This is useful for retrieving meta-information written in response headers, without having to transport the entire content.

TRACE method echoes the received request so that a client can see what (if any) changes or additions have been made by intermediate servers.

CONNECT method converts the request connection to a transparent TCP/IP tunnel, usually to facilitate SSL-encrypted communication (HTTPS) through an unencrypted HTTP proxy.

