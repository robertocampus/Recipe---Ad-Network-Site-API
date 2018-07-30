<cfcomponent extends="taffy.core.api">
	<cfscript>
        boolean function isDashboardEnabled() {
            return structKeyExists(application, "allowedIps") && listFind(application.allowedIps, cgi.remote_addr)>0;
        }

		this.name = "YN_API_v2";
		This.setclientcookies="yes";
		This.applicationTimeout = CreateTimeSpan(1,0,0,0);
		This.sessionManagement  = true;
		This.sessionTimeout 	= CreateTimeSpan(7,0,0,0);
		This.loginStorage 		= "session";

		This.requireAPIAuth  = false;

		this.mappings['/resources'] = expandPath('./resources');
		this.mappings['/taffyAPI'] = expandPath('.');

		this.javaSettings = {
		        loadPaths: [
		            "./lib/"
		        ],
		        loadColdFusionClassPath: true
		    };

		variables.framework = {
			serializer = "taffyAPI.socialfoodieJsonSerializer"
			,docs = {
		         APIName = "Yummie Nation API"
		        ,APIVersion = "Taffy 1.0"
		    }
		    ,allowCrossDomain = "yummienation.com;www.yummienation.com"
		    ,reloadOnEveryRequest = true
		    ,environments = {
		        production = {
		            disableDashboard = true
		            ,reloadOnEveryRequest = false
					,reloadKey = "taffyReinit"
					,reloadPassword = "supersecret"
		        }
		    }
		};

		function getEnvironment(){
		    if ( listfindnocase("localhost,api.yummienation.dev,qa-api.yummienation.com,dev.yummienation.com", CGI.HTTP_HOST) ) {
		        return "development";
		    }else{
		        return "production";
		    }

		}

		function onApplicationStart(){

			lock scope="APPLICATION" type="EXCLUSIVE" timeout="10" {

				// Set Global Variables
				settings.user	  	   = "yummienation";
				settings.base 	  	   = "yummienation";
				settings.title 	  	   = "Yummie Nation";
				settings.tagLine   	   = "Where everyday cooks, influencers and brands unite";
				settings.dsn	   	   = "yummienation";
				settings.datasource	   = "yummienation";
				settings.adsurl		   = "https://ads.yummienation.com";
				settings.widgetUrl     = "https://widget.yummienation.com";
				settings.forum_dsn 	   = "";
				settings.emailServer   = "mail.yummienation.com";
				settings.adminEmail    = "accounts@#settings.base#.com";
				settings.supportEmail  = "support@#settings.base#.com";
				settings.salesEmail    = "sales@#settings.base#.com";
				settings.emailUsername = "support@yummienation.com";
				settings.emailPassword = "____";
				settings.emailServer   = "imap.gmail.com";
				settings.emailServerPortSMTP = "465"; // imap
				settings.emailServerPortIMAP = "993"; // imap
				settings.emailServerSSL = "yes";
				settings.author		   = "Yummie Nation";
				settings.author_url	   = "http://www.yummienation.com";
				settings.subject	   = "food";
				settings.class		   = "fbr";
				settings.aux	   	   = "aux";
				settings.allowedIPs	   = "184.72.231.79,76.12.169.197";
				settings.AmazonS3["accessKeyId"] = "____";
				settings.AmazonS3["secretAccessKey"] = "____";
				settings.AmazonS3["bucketName"] = "ads.#settings.base#.com";
				settings.assets_imagePath = "https://images.yummienation.com";
				settings.twitter_consumerSecret = '____';
				settings.twitter_consumerKey = '____';
				settings.fbAppID = '____';
				settings.fbAppSecret = '____';

				StructAppend(application, settings);

				// app vars
				if ( getEnvironment() EQ 'development' ) {

					application.url 			= "http://#CGI.HTTP_HOST#";
					application.urlSSL 			= "https://#CGI.HTTP_HOST#";
					application.basePath 		= "#expandPath('./')#";
					application.basePathWeb 	= "";
					application.appBaseURL		= "https://qa.yummienation.com";

				} else {

					application.url 			= "http://api.#application.base#.com";
					application.urlSSL 			= "https://api.#application.base#.com";
					application.basePath 		= "/var/www/api.#application.base#.com/";
					application.basePathWeb 	= "/public_html/";
					application.appBaseURL		= "https://www.yummienation.com";

				}

				application.taffyRootURL 	= "#application.urlSSL#/index.cfm?endpoint=";

				/* basePath for the file write/read variables */
				application.uploadedImagePath 	 = "/data/in/images/";
				application.uploadedS3ImagePath = "/data/out/images/";
				application.importedRecipePath  = "/data/in/recipes/";

				/* Setting Basic Auth details */ 
				application.taffyBasicAuth = "foodieblogroll:yummineation2016";

			}

			/* Object Creation for JSOUP Java library */
			application.jSoupClass 		= createObject( "java", "org.jsoup.Jsoup" );


			/* Object Creation to api/com folder components */
			application.recipeDataObj 		= createObject( "component", "com.recipe_data" );
			application.accountObj 			= createObject( "component", "com.account" );
			application.dataObj 			= createObject( "component", "com.data" );
			application.influencerMetaObj	= createObject( "component", "com.influencerMeta" );
			application.scoreObj			= createObject( "component", "com.score" );

			/* Object Creation to api/com/ingredientParser folder components */
			application.ingredientParser = createObject( "component", "com.ingredientParser.parser" );

			/* Object Creation for amazon s3 bucket web services component*/
			application.s3Obj = createObject("component","com.s3").init(application.amazonS3["accessKeyId"],application.AmazonS3["secretAccessKey"]);

			/* Object Creation for social login tweeter process */
			application.objMonkehTweet = createObject('component','com.coldfumonkeh.monkehTweet')
					.init(
						consumerKey			=	application.twitter_consumerKey,
						consumerSecret		=	application.twitter_consumerSecret,
						parseResults		=	true
					);

			application.val_tables = application.dataObj.getResources().VALUETABLES;
			application.messages  = application.dataObj.getmessages();

			return super.onApplicationStart();
		}

		function onRequestStart(TARGETPATH){

            if (structKeyExists(application, "_taffy") && structKeyExists(application._taffy, "settings")) {
                application._taffy.settings.disableDashboard = !isDashboardEnabled();
            }

			if ( StructKeyExists( URL, "init" ) ) {
				THIS.onApplicationStart();
			};

			if( not structKeyExists(application, "meta") or structKeyExists( URL, "init") ) {
				directory = listToArray(application._TAFFY.BEANLIST);

				for( i=1; i LTE arrayLen(directory); i++ ) {
					resultsOfMethods = createObject("component", "resources." & directory[i] );
					for( key in resultsOfMethods ) {
						application["meta"][directory[i]][key]  = getMetaData(resultsOfMethods[key]) ;
					}
				}
			}

			return super.onRequestStart(TARGETPATH);
		}

		// this function is called after the request has been parsed and all request details are known
		function onTaffyRequest(verb, cfc, requestArguments, mimeExt){			

			// this would be a good place for you to check API key validity and other non-resource-specific validation
			if ( structKeyExists(getHTTPRequestData().headers, "origin") AND listfindnocase("https://service.prerender.io,https://www.yummienation.com,https://yummienation.com,https://qa.yummienation.com,http://dev.yummienation.com,http://yummienation.dev,http://app.yummienation.dev", getHTTPRequestData().headers.origin) ){
				local.origin = getHTTPRequestData().headers.origin;
			}else{
				local.origin = "https://www.yummienation.com";
			}

			if(application._taffy.settings.allowCrossDomain EQ true OR len(application._taffy.settings.allowCrossDomain) GT 0) {
				var response = getPageContext().getResponse();
				response.setHeader("Access-Control-Allow-Origin","#local.origin#" );
				response.setHeader("Access-Control-Allow-Methods", "OPTIONS, DELETE, PUT" );
				response.setHeader("Access-Control-Allow-Headers", "Authorization,origin,content-type,accept,access-control-allow-origin,content-length,host,referer,user-agent,accept-encoding,accept-language" );
				response.setHeader("Access-Control-Allow-Credentials", "true" );
				response.setHeader("Access-Control-Max-Age", "86400" );
			}

			application.twitterCallBack = "#local.origin#/app/dist/pages/twittercallback.html";

			if( verb EQ 'OPTIONS'){
				return representationOf('success').withStatus(200);
			}

			/* Checking Basic Auth verifier*/ 
			authDetails = getBasicAuthCredentials();

			if( NOT ( authDetails.userName EQ 'foodieblogroll' ) OR NOT ( authDetails.password EQ 'yummineation2016' ) ){
				return representationOf('Error: You are not authorize to access this site.').withStatus(401);
			}

			//user to get id from SEO
			if( verb EQ 'GET' AND cfc EQ 'item' OR cfc EQ 'recipe' OR cfc EQ 'influencer' OR cfc EQ 'promotion' OR cfc EQ 'blog' OR cfc EQ 'sponsor' ) {

				if( listLen(requestArguments.id, "_") EQ 2){
					requestArguments.id = listGetAt(requestArguments.id,2, "_");
				}

			}

			if( verb EQ 'GET' AND cfc EQ 'values' AND NOT listfindnocase("api.yummienation.com,qa-api.yummienation.com,api.yummienation.dev,dev.yummienation.com", CGI.HTTP_HOST) ) {

				error['errormessage'] = 'Your Domain is not allowed to access this';
				return representationOf(error).withStatus(401);
			}

			validateObj = createObject("component","validation");
			requestArguments.verb 	= verb;
			requestArguments.cfc 	= cfc;
			authorize = application["meta"][cfc][verb];

			// user authorization checking
			if( structKeyExists(authorize, "auth") and not structKeyExists(requestArguments, "NotAuthorize") ) {

				if( structKeyExists(requestArguments, "auth_token") and trim(len(requestArguments.auth_token) ) AND structKeyExists(requestArguments, "userID") and trim(len(requestArguments.userID) ) ) {

					isAuthorized = validateObj.isAuth( argumentcollection = requestArguments );

					if(not isAuthorized)
						return noData().withStatus(401);

				} else {

					error['errorAvailable'] = true;
					error['errorMessege'] = "";

					if( NOT structKeyExists(requestArguments, "auth_token") ) {

					error.errorMessege = listAppend(error['errorMessege'], "auth_token is required.");

					}

					if( NOT structKeyExists(requestArguments, "userID") ) {

						error.errorMessege = listAppend(error['errorMessege'], "UserID is required.");

					}
					return representationOf(error).withStatus(401);
				}
			}

			// handle without auth_token for Internaly access the API using http.
			if( structKeyExists(requestArguments, "NotAuthorize") ) {
				requestArguments.auth_token = "Internal usage"	;
			}

			// pre arguments validation for API functions
			result = validateObj.preArgumentValidations( argumentcollection = requestArguments );

			if( result.status NEQ true ) {
				return representationOf(result).withStatus(500);
			}

			if ( structKeyExists(requestArguments, "filters") ) {
				// if jSon then convert to Struct via deserializeJSON
				if ( isJSON( requestArguments.filters )  ) {
					requestArguments["filters"] = deserializeJSON(requestArguments.filters);
				};
			};

			if ( structKeyExists(requestArguments, "pagination") ) {
				// if jSon then convert to Struct via deserializeJSON
				if ( isJSON( requestArguments.pagination )  ) {
					requestArguments["pagination"] = deserializeJSON(requestArguments.pagination);
				};
			};


			// Do we require an API KEY and SECRET?
			if ( THIS.requireAPIAuth ) {
							// Yes - check if this user is legit
				if ( structKeyExists( getHttpRequestData().headers, "API_KEY") && structKeyExists( getHttpRequestData().headers, "API_SECRET") ) {

					// writeOutput("API_KEY FOUND: #getHttpRequestData().headers.API_KEY#</br>");
					// writeOutput("API_SECRET FOUND: #getHttpRequestData().headers.API_SECRET#</br>");

					// TMP - code to check against authorized users here
					// TMP - add THROTTLE CODE
					// TMP - add LIMITS CODE
					request.isAuthorized = true;

				} else { // NO API KEY and SECRET FOUND - NOT AUTHORIZED

					request.isAuthorized = false;

				};

			} else {
				request.isAuthorized = true;
			};

			return true;
		}
	</cfscript>
</cfcomponent>
