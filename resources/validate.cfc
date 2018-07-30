<cfcomponent extends="taffyAPI.base" taffy:uri="/validate/" hint="Used to validate the data which are already place in table.">

		
	<cffunction name="POST" returntype="Struct" access="public" hint="Import recipes details form users wordpress blog" output="false">
		<cfargument name="functionName"  type="string" 	default="" 	required="true" >
		<cfargument name="attributes" 	 type="string" 	default="" 	required="true" >		

		<cfset structAppend( arguments, deserializeJson( arguments.attributes ) )>
		
		<cfsetting requesttimeout="18000000">

		<cfscript>

			jSoupClass 	 = createObject( "java", "org.jsoup.Jsoup" );
			userBrowser  = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.122 Safari/534.30";

			result = structNew();
			result["error"] 	   = false ;
			result["errors"] 	   = "" ;
			result["errorsforlog"] = "" ;
			result["message"]	   = "" ;
			/* START: Validation functions starts from here. */ 
			switch (arguments.functionName) {
				
				/* START: Function to check the blog URL is valid or not? */ 
				case "bolgURLValidate":{

					try{
						if (structKeyExists(arguments,'RssURL')) {

							if( NOT len(trim(arguments.RssURL)) OR NOT isValid("URL", arguments.RssURL) ) {
								
								result['errors'] = listAppend(result['errors'], "RssURL");
								result["message"]	= listAppend(result['message'],"Please give the valid RssURL.") ;
						  		result['errorsforlog'] = listAppend(result['errorsforlog'], "The given RssURL is not valid, " & arguments.RssURL);
							
							} else { 

								http = new http();

								http.settimeout(3000);

								http.seturl( arguments.RssURL );
								http.setMethod( 'GET' );

								returnData = http.send().getPrefix();

								if( returnData.statuscode NEQ '200 OK' ) {
									result['error'] 	= true;
									result["message"]	= listAppend(result['message'],"Please give the valid RssURL.");
									return representationOf(result).withStatus(200);
								} else {

									result["message"]	= listAppend(result['message'],"RssURL is valid");
									return representationOf(result).withStatus(200);
								}

							}

							return representationOf(result).withStatus(406);
						
						}

						if (structKeyExists(arguments,'blogURL')) {


							if( NOT len(trim(arguments.blogURL)) OR NOT isValid("URL", arguments.blogURL) ) {
							
								result['errors'] = listAppend(result['errors'], "blogURL");
								result["message"]	= listAppend(result['message'],"Please give the valid blogURL.") ;
						  		result['errorsforlog'] = listAppend(result['errorsforlog'], "The given blogURL is not valid, " & arguments.blogURL);
							
							} else {

								response = jSoupClass.connect(arguments.blogURL).userAgent(userBrowser).timeout(15000).execute();
								
								if( response.statuscode() EQ '200' ) {

									redirectURL = response.url().toExternalForm();

									match = reReplaceNoCase(redirectURL,'http(://www.|://|s://www.|s://)','');
									match = rePlace(match,'com/','com');

									if( match EQ reReplaceNoCase(arguments.blogURl,'http(://www.|://|s://www.|s://)','') OR redirectURL EQ arguments.blogURL ){
								
										local.attributes.filters.blogURL  = arguments.blogURL;
										checkUrlIsExist  = httpRequest( methodName = 'GET', endPointOfURL = '/blogs/', timeout = 3000, parameters = local.attributes );
									
										blogFileContent  = deserializeJSON(checkUrlIsExist.fileContent);

										if(blogFileContent.TOTAL_COUNT NEQ 0){

											result["error"]		   = true;
											result["message"]	   = listAppend(result['message'],"BlogURL already exists");
											return representationOf(result).withStatus(200);

										}
										
										dom = jSoupClass.connect(arguments.blogURL).userAgent(userBrowser).timeout(180000).ignoreHttpErrors(true).get();
										
										result['blogTitle']   = dom.select('title').text();
										result['description'] = dom.select('meta[name="description"]').attr('content');
										result["message"]	   = listAppend(result['message'], "success") ;								

									}else{
										result["error"]	 = true;
										result['errors'] = listAppend(result['errors'], "blogURL");
							  			result['errorsforlog'] = listAppend(result['errorsforlog']," redirection found");
							  			result["message"]	   = listAppend(result['message'],"This URL is invalid! We detected a redirect to #redirectURL#.") ;
									}
								} else {

									result["error"]	 = true;
									result['errors'] = listAppend(result['errors'], "blogURL");
						  			result['errorsforlog'] = listAppend(result['errorsforlog']," The page " &arguments.blogURL&" does not contain the valid blog details.");
						  			result["message"]	   = listAppend(result['message'],"The page does not contain the valid blog details.") ;

								}
								return representationOf(result).withStatus(200);

							}
						
						}

					} catch( any e ){

						if ( e.type EQ 'java.net.SocketTimeoutException' OR e.type EQ 'java.net.UnknownHostException' OR e.type EQ 'org.jsoup.HttpStatusException' ){
							
							result["error"]	 = true;
							result['errors'] = listAppend(result['errors'], "URL Error");
				  			result['errorsforlog'] = listAppend(result['errorsforlog'],"The URL which you provide was in valid.");
							result["message"]	   = listAppend(result['message'], "The URL which you provide was in valid.") ;
							return representationOf(result).withStatus(200);

						}						
						
					}
					return noData().withStatus(500);
					break;
				}
				/* END: Function to check the blog URL is valid or not? */ 

				
				case "ingredient_line":{

					ingredient = arguments.ingredient;

					result.ingredient_status = {};

					regex1 = "^((\d+)|(\d+\/\d+)|(\d+)\s(\d+\/\d+)|(\d+-\d+))\s((dash|pinch|tsp|tbs|fl oz|cup|pt|qt|gal|oz|lb|cl|can|c|C|cups|kg|kgs|l|L|lt|Lt|lit|g|G)|(dash|pinch|teaspoon|tablespoon|fluid ounce|cup|pint|quart|gallon|ounce|pound|fresh|clove|small|medium|large|slice|hand|of|turnip|drizzle|box|big))(s)?\b\s[A-Za-z0-9(,|\-|&|:|!|" & "'|" & '"' & ")\s]+[A-Za-z(,|\-|&|:|!|" & "'|" & '"' & ")\s]+$";

					regex2 = "^((\d+)|(\d+.\d+))\s((kg|g|lb|cl)|(kilogram|gram|pound|small|drizzle|hand|big|medium|large|box))(s)?\b\s[A-Za-z0-9(,|\-|&|:|!|" & "'|" & '"' & ")\s]+[A-Za-z(,|\-|&|:|!|" & "'|" & '"' & ")\s]+$";
				
					regex3 = "^((a|an|extra))\s[A-Za-z0-9(,|\-|&|:|!|" & "'|" & '"' & ")\s]+[A-Za-z(,|\-|&|:|!|" & "'|" & '"' & ")\s]+$";

						// local.specialChar = {"½":"1/2","¼":"1/4","¾":"3/4","⅔":"2/3","⅕":"1/5","⅖":"2/5","⅗":"3/5","⅘":"4/5","⅙":"1/6","⅚":"5/6","⅛":"1/8","⅜":"3/8","⅝":"5/8","⅞":"7/8","&":"and","´":"'","’":"'","–":"-"};

					 // 	for( key in local.specialChar){

						// 	arguments.ingredient=replace(arguments.ingredient, key, structFind(local.specialChar,key), "all");
						// }

						local.ingredient = application.recipeDataObj.removeSpecialChars(arguments.ingredient);
						arguments.ingredient = local.ingredient.ingredientline;
						local.ingredientDetails = application.ingredientParser.parse( arguments.ingredient );

						if( local.ingredientDetails.result AND (isValid( "regex", lCase(arguments.ingredient), regex1 ) OR isValid( "regex", lCase(arguments.ingredient), regex2 ) OR isValid( "regex", lCase(arguments.ingredient), regex3 ) ) ){

							local.ingredientValue = listToArray(local.ingredientDetails.name, ' ');

							for( ingredientName in local.ingredientValue ){
							
								/* Checking the USDA_food_desc table with only ingredients */ 
						 		local.usdaIngredient = application.recipeDataObj.getIngredientValues(ingredient = ingredientName);

							 	if( local.usdaIngredient.recordcount ) {						 		
							 		result['error'] = false;
							 		result["errors"] ='';
							 		result['message'] = listAppend(result['message'],'Everythig is fine','||' );
							 		structInsert( result.ingredient_status, 'ingredient', arguments.ingredient ,true);
							 		structInsert( result.ingredient_status, 'status', 'Y', true );
							 		break;
							 		
							 	}
							}

							if( NOT listLen(result['message'])) {

								result["error"] = true;
								result["errors"] = listAppend( result["errors"], arguments.ingredient, '||' );
								result['message'] = listAppend(result['message'],"ingredient:::We couldn't match this ingredient to any in our database","||");
								structInsert( result.ingredient_status, 'ingredient', arguments.ingredient ,true);
								structInsert( result.ingredient_status, 'status', 'N', true );

							}
							

						} else {

							// if( NOT listFind(checkAmount,listFirst(arguments.ingredient,' '))  OR NOT isnumeric(listFirst(arguments.ingredient,' '))){
							// 	result["error"] = true;
							// 	result['message'] = "we can't find a valid unit amount";
							// }
							unitAmountRegex = "^((a|an)|(\d+)|(\d+\/\d+)|(\d+)\s(\d+\/\d+)|(\d+-\d+))+$";
							unitRegex = "^((dash|pinch|tsp|tbs|fl oz|cup|pt|qt|gal|oz|lb|cl|can|c|C|l|L|lt|ml|g|G|kg|KG|Kg|Lt|kgs)|(dash|pinch|teaspoon|tablespoon|fluid ounce|cup|pint|quart|gallon|ounce|pound|fresh|clove|small|medium|large|slice|hand|turnip|drizzle|box|big|kilo|kilo grams|kilo gram|liter|liters|lit|cups))+$"

							if( NOT isValid( "regex", lCase(listFirst( arguments.ingredient ," ")), unitAmountRegex ) ){
								result["error"] = true;
								result['message'] = listAppend(result["message"],"unit amount:::we can't find a valid amount type, edit to change unit type or just leave as is","||");
							}

							if( NOT isValid( "regex", lCase(ListFirst(listrest( arguments.ingredient , " "), " " )), unitRegex ) ){
								result["error"] = true;
								result['message'] = listAppend(result["message"],"unit:::we can't find a valid unit type, edit to change unit type or just leave as is","||");
							}

							if( NOT isValid( "regex", lCase(ListFirst(listrest( arguments.ingredient , " "), " " )), unitRegex ) AND NOT isValid( "regex", lCase(listFirst( arguments.ingredient ," ")), unitAmountRegex ) ){
								result["error"] = true;
								result['message'] = "unit amount:::we can't find a valid unit type or amount, edit to change unit type or just leave as is";
							}

							if( NOT result["error"] ){
								result["error"] = true;
								result['message'] = listAppend(result["message"],"ingredient:::We couldn't match this ingredient to any in our database","||");
							}

							result["error"] = true;
							result["errors"] = listAppend( result["errors"], arguments.ingredient, '||' );

							structInsert( result.ingredient_status, arguments.ingredient, 'N', true );
								
						}

					if( listLen(result["errors"]) ) {
						return representationOf(result).withStatus(404);
					} else {
						return representationOf(result).withStatus(200);
					}

					break;
				}

				case "recipeIndex":{
					
					requiredArgumentsAsArray = listToArray("userID,url,auth_token");

					for( element in requiredArgumentsAsArray ) {
						if( NOT structKeyExists(arguments, element) OR ( structKeyExists(arguments, element) AND NOT len(trim(arguments[element]))) ) {
				  			result['errors'] = listAppend(result['errors'], element);
				  			result['errorsforlog'] = listAppend(result['errorsforlog'], element & " is required");
				  		}
					}

					if( structKeyExists(arguments, "url") AND NOT isValid("URL", arguments.url) ) {
						result['errors'] = listAppend(result['errors'], arguments.url);
				  		result['errorsforlog'] = listAppend(result['errorsforlog'], arguments.url & " is invalid.");
					}

					if( listLen( result['errors'] ) GT 0 ) {
						result['error'] = true;

						return representationOf(result).withStatus(500);

					} else {

						param name="arguments.blogID" value="";
						param name="arguments.isDetectRecipeSEO" value="";

						local.attributes = {};

						local.attributes.auth_token = arguments.auth_token;
						local.attributes.userID = arguments.userID;

						//check authentication
						checkAuthentication = httpRequest( methodName = 'GET', endPointOfURL = '/authorize', timeout = 3000, parameters = local.attributes );

						if( checkAuthentication.status_code EQ 200 ) {
							getSession = deserializeJSON( checkAuthentication.fileContent );
						}

						//unautherized
						if( checkAuthentication. status_code EQ 401 OR ( checkAuthentication.status_code EQ 200 AND getSession.session_available IS false ) ) {

							return noData().withStatus(401);

						} else {

							//checking the url is valid or not
							http = new http();

							http.settimeout(3000);

							http.seturl( arguments.url );
							http.setMethod( 'GET' );

							returnData = http.send().getPrefix();

							if( returnData.statuscode EQ '200 OK' ) {

								//just insert record in recipes_importTasks table
								importTaskID = application.recipeDataObj.createRecipeImportTask( source_url = arguments.url, current_row = 0, UserID = arguments.userID, blogID = arguments.blogID );
								
								urlDomainName = listToArray(arguments.url,'/');
								domainName	  = listToArray(urlDomainName[2], '.');

								if( domainName[1] EQ 'www' ){

									checkDomain = listRest(urlDomainName[2], '.');

								}else{

									checkDomain = urlDomainName[2];									

								}

						   		dom = application.jSoupClass.connect( arguments.url ).userAgent(userBrowser).get();

						   		parentURL = dom.select('a');
						   		
						   		// if isDetectRecipeSEO is exist in arguments, allow to extract links and insert into recipes_import table 
						   		if( parentURL.size() AND structKeyExists(arguments, "isDetectRecipeSEO") AND arguments.isDetectRecipeSEO EQ 0 ) {

						   			// if URL's found, just update record in recipes_importTasks table with isError=0
						   			application.recipeDataObj.updateRecipeImportTaskByID( importTaskID = importTaskID, isError = 0 );
									
									var validURLs = [];

						   			for( i=1; i<parentURL.size(); i++ ) {

						   				if( len( trim(parentURL[i].attr("abs:href")) ) ){

							   				LinkDomainName = listToArray(parentURL[i].attr("abs:href"),'/');
							   				currentDomainName = listToArray(LinkDomainName[2], '.');

											if( currentDomainName[1] EQ 'www' ){

												checkCurrentDomain = listRest(LinkDomainName[2], '.');

											}else{

												checkCurrentDomain = LinkDomainName[2];

											}

							   				if( checkDomain EQ checkCurrentDomain ) {
							   				
								   				if( NOT arrayfindnocase( validURLs, processURL(trim(parentURL[i].attr("abs:href"))) ) ){

								   					arrayAppend(validURLs, processURL( trim(parentURL[i].attr( "abs:href" )) ) );

								   					application.recipeDataObj.createRecipeImport( importTaskID = importTaskID, source_url = processURL( trim(parentURL[i].attr( "abs:href" )) ), userID = arguments.userID);

								   				}
							   				}
						   				}
									}
									
									// get recipeImports record by importTaskID
									result['query'] = application.recipeDataObj.readRecipeImports( importTaskID = importTaskID );

									result['total_rows'] = result['query'].recordCount;
									result['current_row'] = 0;

									//update total_rows after enter record.
									application.recipeDataObj.updateRecipeImportTaskByID( importTaskID = importTaskID, total_rows = result['total_rows'], isParsed = 1, isError = 0 );

									result['message'] = "inserted successfully..";

									return representationOf(result).withStatus(200);

					   			} else {

					   				// if no URL's found, just update record in recipes_importTasks table with isError=1
					   				application.recipeDataObj.updateRecipeImportTaskByID( importTaskID = importTaskID, isError = 1 , isParsed = 0, total_rows = 0);

					   				result['message'] = 'URL not found on this page';
					   				result['error'] = true;

					   				return representationOf(result).withStatus(404);
					   			}

							} else {

								result['message'] = 'invalid URL';
					   			result['error'] = true;

					   			return representationOf(result).withStatus(404);
							}
						}
					}

					break;
 				}

 				case "recipePageHasSEO": {

 					if( NOT structKeyExists(arguments,"url") OR structKeyExists(arguments,"url") AND NOT len(trim(arguments.url))){

 						result['errors'] = listAppend(result['errors'], arguments.url);
				  		result['errorsforlog'] = listAppend(result['errorsforlog'], arguments.url & " is required");
 					}

 					if ( isValid( "URL", arguments.url ) EQ false ) {
						result['errors'] = listAppend(result['errors'], "url");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "url: #arguments.url#");
					}

					if( listLen( result['errors'] ) GT 0 ) {
						result['error'] = true;

						return representationOf(result).withStatus(500);

					} else {

						
						http = new http();

						http.settimeout(3000);

						http.seturl( arguments.url );
						http.setMethod( 'GET' );

						returnData = http.send().getPrefix();

						if( returnData.statuscode EQ '200 OK' ) {

					        dom = jSoupClass.connect(arguments.url).userAgent(userBrowser).timeout(180000).ignoreHttpErrors(true).get();
					        // metaHasHttp = dom.select('meta').hasAttr('http-equiv');
					        googleVerification = dom.select('*[itemprop]').size();

					        if ( googleVerification ) {

					            result['recipeHasSEO'] = true;

					            return representationOf(result).withStatus(200);

					        } else {

					            result['recipeHasSEO'] = false;

					            return representationOf(result).withStatus(404);

					        }

					    } else {

					    	result['errors'] = listAppend(result['errors'], "url");
							result['errorsforlog'] = listAppend(result['errorsforlog'], "url: NA");

							return representationOf(result).withStatus(404);
					        
					    }
					}
					break;
 				}

 				default: {

 					result.error  	    = true ;
					result.errors 	    = 'Invalid Type';
					result.errorsforlog = listAppend( result.errorsforlog, arguments.functionName & ' is invalid type.' );

					return representationOf(result).withStatus(404);

					break;
 				}
			}
			/* END: Validation functions ends from here. */ 
		
		</cfscript>

	</cffunction>

	<cffunction name="processURL" access="private" returntype="Any" hint="Used to separate Query string and hash values from the URL">
		<cfargument name="getURL" type="string" required="true" displayname="URL string value">
		<cfset var endpos = 0 >

		<cfif arguments.getURL.indexOf("?") GT 0>
			<cfset endpos = arguments.getURL.indexOf("?")>
		<cfelseif arguments.getURL.indexOf("##") GT 0>
			<cfset endpos = arguments.getURL.indexOf("##")>
		<cfelse>
			<cfset endPos = len(getURL) >
		</cfif>

		<cfreturn arguments.getURL.substring(0, endPos)/>

	</cffunction>	
	
</cfcomponent>