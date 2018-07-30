<cfcomponent extends="taffyAPI.base" taffy:uri="/recipesImport/" hint="Used to import wordpress blog's recipes details.">
	
	<cfsetting requesttimeout="40000">

	<cffunction name="POST" access="public" returntype="Struct" hint="Import recipes details form users wordpress blog" output="false" auth="true">
		<cfargument name="type"  		type="string"  	required="true" >
		<cfargument name="userID" 		type="numeric" 	required="true" >
		<cfargument name="auth_token"  	type="string"  	required="true" >
		<cfargument name="url"  		type="string"  	required="false" default="" >
		<cfargument name="blogID" 		type="numeric" 	required="false" default="0" >
		<cfargument name="importTaskID" type="numeric"  required="false" default="0" >
		<cfargument name="importID" 	type="numeric"  required="false" default="0" >
		<cfargument name="attributes"   type="string"   required="false" default=""  >
		
		<cfset result = structNew() >

		<cfset result['error'] = false >
		<cfset result['errors'] = "" >
		<cfset result['errorsForLog'] = "" >
		<cfset result['recipeImportStatus'] = "failure" >
		<cfset result['message'] = "">
		<cfset result['status']  = false>
		<cfset userBrowser  = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.30 (KHTML, like Gecko) Chrome/12.0.742.122 Safari/534.30">

		<cfscript>
			
			switch(arguments.type) {

				/* Parse the given URL pages using JSOUP HTML Parser and extracting the recipe post details */ 
				case 'recipe': {

					local.timeToComplete = structNew();
				    local.recipesHeadItems = structNew();
				    local.ingredientItems = arrayNew();
				    local.recipeInstruction = arrayNew();
				    local.imageSource = '';
				    imageName = '';
				    imageID = 0;

				    
				    local.isError = 0;
				    local.isParsed = 1;
				    local.isValid = 1;

					// verify recipeTitle
					if ( LEN( TRIM( arguments.URL ) ) EQ 0 OR NOT isValid("URL", arguments.URL )) {
						result['errors'] = listAppend(result['errors'], "URL is invalid");
						result['errorsforlog'] = listAppend(result['errorsforlog'], "URL: #arguments.URL#");
					}

					// verify recipeTitle
					if ( LEN( TRIM( arguments.URL ) ) AND isValid("URL", arguments.URL ) ) {
						 //checking the URL is valid or not
					    http = new http();

					    http.settimeout(3000);
					    http.seturl( arguments.url );
					    http.setMethod( 'GET' );

					    recipeSourcePage = http.send().getPrefix();

					    if( recipeSourcePage.statuscode NEQ '200 OK' ){

						    result.errors = listAppend(result['errors'], "Blog post page does not have a valid recipes data." );
							result.errorsForLog = listAppend(result['errorsforlog'], "Not a valid page.");
						}
					}

					
				   

				    if( ListLen(result['errors']) GT 0  ) {

				    	//creating a html page with source URL
				    	local.isError = 1 ;
					    local.isParsed = 0 ;
					    local.isValid = 0 ;

					    result.error = true ;
						

						return representationOf(result).withStatus(500);

					} else {

						dom = application.jSoupClass.connect( arguments.url ).userAgent(userBrowser).get();
					    filePath = expandpath(application.importedRecipePath);

					    if( NOT directoryExists(filePath) ) {
					    	directorycreate(filePath);
						}

						fileName = createUUID();
					    fileWrite(filePath&'#fileName#.html',recipeSourcePage.filecontent);

					    //Getting the recipe details from html page's meta tags
					    post = dom.select("meta");
					    wordPressVersion = post.select('meta[name="generator"]').attr('content');

					    siteURL 	= post.select('meta[property="og:url"]').attr('content');
					    authorName 	= post.select('meta[property="og:site_name"]').attr('content');
					    title 		= post.select('meta[property="og:title"]').attr('content');
					    description = post.select('meta[property="og:description"]').attr('content');
					    tags 		= post.select('meta[property="article:tag"]');
					 						    
					    tagList = '';

					    for ( tag in tags ) {
					    	tagList = listAppend( tagList, tag.attr('content'));
						}

						//Available only for EasyRecipes plug-in
					    recipeEasy 	     = dom.select('div.easyrecipe *[itemprop]');
					    //Available only for zipList plug-in
					    recipeZipList 	 = dom.select('div.zlrecipe-container-border *[itemprop]');
					    //Available only for WPUltimate plug-in
				    	recipeWPUltimate = dom.select('div.wpurp-container *[itemprop]');
						//Available only for Yummly Rich Recipe SEO plug-in
						recipeYrecipe 	 = dom.select('div.yrecipe-container-border *[itemprop]');
					
						//Available only for EasyRecipes plug-in							
				    	if( arrayLen(recipeEasy) ) {

				    		recipeEasy = dom.select('div.easyrecipe').eq(0);
				    		completeTime = 0;

				    		local.imageSource 	= recipeEasy.select('img[itemprop="image"]').attr("abs:src");

					        local.totalServings = val(recipeEasy.select('span[itemprop="recipeYield"]').text());
					        description = recipeEasy.select('[itemprop="description"]').text();
					        preparationTimes 	= recipeEasy.select('time[itemprop]');
					        recipesItems 		= recipeEasy.select('span[itemprop]');
					        recipesIngredients 	= recipeEasy.select('li[itemprop="ingredients"]');
					        recipesInstruction 	= recipeEasy.select('li[itemprop="recipeInstructions"]');

					        for( time in preparationTimes ) {

					        	cookTime = replacenocase("#time.text()#",',','','all');

								convertToMinutes = listToArray(cookTime,' ');

								if( arrayfindnocase(convertToMinutes,'hour') OR arrayfindnocase(convertToMinutes,'hr')){

									hoursToMins = val(convertToMinutes[1])*60;

									if( arrayfindnocase(convertToMinutes,'minutes') OR arrayfindnocase(convertToMinutes,'mins') ){

										completeTime = val(convertToMinutes[3]) + hoursToMins;

									}else{

										completeTime = hoursToMins;

									}

								}else if( arrayfindnocase(convertToMinutes,'minutes') OR arrayfindnocase(convertToMinutes,'mins')){

									completeTime = val(convertToMinutes[1]);

								}

					        	structInsert( local.timeToComplete, "#time.attr('itemprop')#", completeTime );
					    	}

					    	for( recipeItem in recipesItems ) {
					    		structInsert( local.recipesHeadItems, "#recipeItem.attr('itemprop')#", recipeItem.text() );
					    	}

					    	for( recipeIngredient in recipesingredients ) {
					    		local.ingredient = application.recipeDataObj.removeSpecialChars(recipeIngredient.text());
								ingredient_text = local.ingredient.ingredientline;
					    		arrayAppend( local.ingredientItems,ingredient_text );
					    	}
					    	

					    	for( instruction in recipesInstruction ) {
					    		arrayAppend( local.recipeInstruction, instruction.text() );
					    	}
					    	result.message = application.messages['recipesimport_post_import_success'];
				    	
				    	} else if ( arrayLen(recipeZipList) ) {

				    	//Available only for zipList plug-in
				    		completeTime = 0;

					        local.imageSource 	= recipeZipList.select('img[itemprop="image"]').attr("abs:src");
					        local.totalServings = val(recipeZipList.select('span[itemprop="recipeYield"]').text());
					        						        
					        preparationTimes 	= recipeZipList.select('span[itemprop]');
					        recipesIngredients 	= recipeZipList.select('li[itemprop="ingredients"]');
					        recipesInstruction 	= recipeZipList.select('li[itemprop="recipeInstructions"]');
					        
					        for( time in preparationTimes ) {

					        	cookTime = replacenocase("#time.text()#",',','','all');

								convertToMinutes = listToArray(cookTime,' ');

								if( arrayfindnocase(convertToMinutes,'hour') ){

									hoursToMins = val(convertToMinutes[1])*60;

									if( arrayfindnocase(convertToMinutes,'minutes') ){

										completeTime = val(convertToMinutes[3]) + hoursToMins;

									}else{

										completeTime = hoursToMins;

									}

								}else if( arrayfindnocase(convertToMinutes,'minutes') ){

									completeTime = val(convertToMinutes[1]);

								}

					        	structInsert(local.timeToComplete, "#time.attr('itemprop')#", completeTime);
					    	}

					    	for( recipeIngredient in recipesingredients ) {
					    		local.ingredient = application.recipeDataObj.removeSpecialChars(recipeIngredient.text());
								ingredient_text = local.ingredient.ingredientline;
					    		arrayAppend( local.ingredientItems,ingredient_text );
					    	}
					    	

					    	for( instruction in recipesInstruction ) {
					    		arrayAppend(local.recipeInstruction, instruction.text());
					    	}
					    	result.message = application.messages['recipesimport_post_import_success'];
				    	} else if( arrayLen(recipeWPUltimate) ) {

				    		//Available only for WPUltimate plug-in
				    		finalPrepareTime = 0;
				    		finalCookTime	 = 0;
				    		finalTotalTime	 = 0;


				    		local.imageSource   = recipeWPUltimate.select('img[itemprop="image"]').attr("abs:src");
					    	local.totalServings = dom.select('div.wpurp-container span.wpurp-recipe-servings-changer input').attr("value");
					        						        
					    	initialPrepareTime 	= val(dom.select('table span.wpurp-recipe-prep-time').eq(0).text());
					    	prepareTimeUnits   	= dom.select('table span.wpurp-recipe-prep-time-text').eq(0).text();
					    	
					    	if( prepareTimeUnits EQ 'hour' ){

					    		finalPrepareTime = initialPrepareTime * 60;

					    	}else if( prepareTimeUnits EQ 'minutes' ){

					    		finalPrepareTime = initialPrepareTime;

					    	}

					    	local.timeToComplete.prepTime = finalPrepareTime;
					    	
					    	initialCookTime = val(dom.select('table span.wpurp-recipe-cook-time').eq(0).text());
					    	cookTimeUnits   = dom.select('table span.wpurp-recipe-cook-time-text').eq(0).text();

					    	if( cookTimeUnits EQ 'hour' ){

					    		finalCookTime = initialCookTime * 60;

					    	}else if( cookTimeUnits EQ 'minutes' ){

					    		finalCookTime = initialCookTime;
					    		
					    	}

					    	local.timeToComplete.cookTime = finalCookTime;

					    	initialTotalTime = val(dom.select('table span.wpurp-recipe-passive-time').eq(0).text());
					    	TotalTimeUnits   = dom.select('table span.wpurp-recipe-passive-time-text').eq(0).text();
					        
							if( TotalTimeUnits EQ 'hour' ){

					    		finalTotalTime = initialTotalTime * 60;

					    	}else if( TotalTimeUnits EQ 'minutes' ){

					    		finalTotalTime = initialTotalTime;
					    		
					    	}		

					    	local.timeToComplete.totalTime = finalTotalTime;			    	

					        local.recipesHeadItems.recipeCuisine = dom.select('li span.wpurp-recipe-tag-terms a').eq(1).text();

					        recipesIngredients = recipeWPUltimate.select('li[itemprop="ingredients"]');						      ;
					        recipesInstruction = recipeWPUltimate.select('span[itemprop="recipeInstructions"]');

					        for( recipeIngredient in recipesingredients ) {
					        	local.ingredient = application.recipeDataObj.removeSpecialChars(recipeIngredient.text());
								ingredient_text = local.ingredient.ingredientline;
					    		arrayAppend( local.ingredientItems,ingredient_text );
					    	}
					    	

					    	for( instruction in recipesInstruction ) {
					    		arrayAppend(local.recipeInstruction, instruction.text());
					    	}
					    	result.message = application.messages['recipesimport_post_import_success'];
				    	} else if(arrayLen(recipeYrecipe)) {
							//Available only for Yummly Rich Recipe SEO plug-in
							completeTime = 0;

							
							totalServings = recipeYrecipe.select('span[itemprop="recipeYield"]').text();
							local.totalServings = arrayToList(rematch("[\d]+",totalServings));


							recipesIngredients  = recipeYrecipe.select('li[itemprop="ingredients"]');
							recipesInstruction  = recipeYrecipe.select('li[itemprop="recipeInstructions"]');
							recipesratingValue  = recipeYrecipe.select('span[itemprop="ratingValue"]').text();

						
							for( recipeIngredient in recipesingredients ) {
					    		local.ingredient = application.recipeDataObj.removeSpecialChars(recipeIngredient.text());
								ingredient_text = local.ingredient.ingredientline;
					    		arrayAppend( local.ingredientItems,ingredient_text );
					    	}
					    	

					    	for( instruction in recipesInstruction ) {
					    		arrayAppend( local.recipeInstruction, instruction.text() );
					    	}
					    	result.message = application.messages['recipesimport_post_import_success'];
						} else {
				    		
				    		if( structKeyExists(arguments, "importTaskID") AND val(arguments.importTaskID) NEQ 0 AND structKeyExists(arguments, "importID") AND val(arguments.importID) ) {

				    			application.recipeDataObj.updateRecipeImportTaskCurrentRow( importTaskID = arguments.importTaskID , currentRow = 1 );

				    		}

				    		result.recipeImportStatus = "failure";
				    		result.errorsForLog = listAppend(result['errorsforlog'], "Given URL does not contains a valid recipe post.");
				    		result.message = application.messages['recipesimport_post_import_error'];
				    		//If user provide a wrong URL or URL doesnot used the above plugin.
				    		return representationOf(result).withStatus(200);
				    	}

				    	if( local.imageSource NEQ '' ) {

				    		//generating file name for image
						    imageName = 'recipe_'&createUUID()&'.'&listLast(local.imageSource, '.');

						    //path to store the import recipes images
						    imageFilePath = expandPath(application.uploadedImagePath);

						    if( NOT directoryExists(imageFilePath) ) {
						    	directorycreate(imageFilePath);
							}

							//uploading image to the server folder
						    downloadAndUploadFile( fileURL = local.imageSource, filePath = imageFilePath, fileName = imageName );

						    imageID = application.recipeDataObj.insertImage( 
				    														imageName = imageName,				    														
				    														imagePath = '#application.urlSSL##application.uploadedImagePath##imageName#',
				    														userID = arguments.userID,
				    														active = 0
				    														);
						}

						if( arrayLen(local.recipeInstruction) EQ 1 ) {

							local.singleInstruction = arrayToList(local.recipeInstruction);


							listOfDelims = ('.,#Chr(10)&Chr(13)#,;,|,||,\,/');


							for( i=1;i<=listLen(listOfDelims);i++ ) {

						 		if(listLen(local.singleInstruction,listGetAt(listOfDelims,i)) > 1) {

									local.recipeInstruction = listToArray(local.singleInstruction,listGetAt(listOfDelims,i));
									break;
								} 


							}

						}
						
						if( structKeyExists(arguments, "importTaskID") AND val(arguments.importTaskID) NEQ 0 AND structKeyExists(arguments, "importID") AND val(arguments.importID) ) {

							//update query
							local.updateRecipe = application.recipeDataObj.updateRecipeImport(

								importID 	 = arguments.importID,
								importTaskID = arguments.importTaskID,
								source_url   = arguments.url,
				    			ingredients  = arrayToList(local.ingredientItems,':::'),
				    			instructions = arrayToList(local.recipeInstruction,':::'),
				    			description  = description,
								sourceTypeID = 3,
								image    = imageName,
				    			imageID  = imageID,
								author   = authorName,
								title    = title,
				    			userID   = arguments.userID,
				    			blogID   = arguments.blogID,
				    			isError  = local.isError,
				    			isParsed = local.isParsed,
				    			isValid  = local.isValid,
				    			cuisine  = (structkeyExists(local.recipesHeadItems,'recipeCuisine')?structFind(local.recipesHeadItems, 'recipeCuisine'):''),
								prep_time	= (structkeyExists(local.timeToComplete,'prepTime')?structFind(local.timeToComplete, 'prepTime'):''),
				    			cook_time 	= (structkeyExists(local.timeToComplete,'cookTime')?structFind(local.timeToComplete, 'cookTime'):''),
				    			total_time 	= (structkeyExists(local.timeToComplete,'totalTime')?structFind(local.timeToComplete, 'totalTime'):''),
				    			total_servings = local.totalServings,
				    			active = 1

							);

							application.recipeDataObj.updateRecipeImportTaskCurrentRow( importTaskID = arguments.importTaskID , currentRow = 1 );
							
							result.importID 	= arguments.importID;
							result.importTaskID = arguments.importTaskID;

						} else {

							//Inserting temporary recipes details into recipes_import tables
					    	result.importID  = application.recipeDataObj.insertRecipeImport(

								source_url 	 = arguments.url,
								sourceTypeID = 3,
								image  = imageName,
								author = authorName,
								title  = title,
								prep_time  = (structkeyExists(local.timeToComplete,'prepTime')?structFind(local.timeToComplete, 'prepTime'):''),
				    			cook_time  = (structkeyExists(local.timeToComplete,'cookTime')?structFind(local.timeToComplete, 'cookTime'):''),
				    			total_time = (structkeyExists(local.timeToComplete,'totalTime')?structFind(local.timeToComplete, 'totalTime'):''),
				    			total_servings = local.totalServings,
				    			cuisine = (structkeyExists(local.recipesHeadItems,'recipeCuisine')?structFind(local.recipesHeadItems, 'recipeCuisine'):''),
				    			ingredients  = arrayToList(local.ingredientItems,':::'),
				    			instructions = arrayToList(local.recipeInstruction,':::'),
				    			description = description,
				    			imageID 	= imageID,
				    			userID 		= arguments.userID,
				    			blogID 		= arguments.blogID,
				    			isError 	= local.isError,
				    			isParsed 	= local.isParsed,
				    			isValid 	= local.isValid,
				    			active = 1

							);

						}

						//sending response data by select the inserted query.
						result.query = application.recipeDataObj.getImportedRecipe( importID = result.importID );
						
						result.recipeImportStatus = "success";

						return representationOf(result).withStatus(200);
						
					}

					break;
				}
				/* case to parse the ingredientLine and direction & also validate the ingredientLine*/
				case "RecipeTextParser" : {

					result['draftRecipes'] = {};
					result.draftRecipes['recipeIngredients']  = [];
					result.draftRecipes['recipeInstructions'] = [];


					/* Converting the request JSON data to structure */ 
					structAppend( arguments, deserializeJson( arguments.attributes ) );

					listOfDelims = ('#Chr(10)&Chr(13)#,;,|,||,.,\,/');


					for( i=1;i<=listLen(listOfDelims);i++ ) {

				 		if(listLen(arguments.instructions,listGetAt(listOfDelims,i)) > 1) {

							result.draftRecipes['recipeInstructions'] = listToArray(arguments.instructions,listGetAt(listOfDelims,i));
							break;
						} 


					}
					

					for( i=1;i<=listLen(listOfDelims);i++ ) {

						if( listLen(arguments.ingredients,listGetAt(listOfDelims,i) ) > 1) {
							local.ingredient = application.recipeDataObj.removeSpecialChars(arguments.ingredients);
							arguments.ingredients = local.ingredient.ingredientline;
							result.draftRecipes['recipeIngredients']  = listToArray(arguments.ingredients,listGetAt(listOfDelims,i));
							break;
						}

					}

					// if no separator matched for instructions

					if( NOT arrayLen(result.draftRecipes['recipeInstructions']) ) {

						result.draftRecipes['recipeInstructions'] = listToArray(arguments.instructions,',');

					}

					// if there is only one ingredient parsed

					if( NOT arrayLen(result.draftRecipes['recipeIngredients']) ) {
							local.ingredient = application.recipeDataObj.removeSpecialChars(arguments.ingredients);
							arguments.ingredients = local.ingredient.ingredientline;
						arrayAppend(result.draftRecipes['recipeIngredients'], arguments.ingredients);

					}

					result.recipeImportStatus = "success";

					return representationOf(result).withStatus(200);

					break;
				}

				/* Parse the given URL using JSOUP HTML Parser to get the bloggers details */ 
				case "Bloggers":{

					if ( NOT structKeyExists(arguments, "url") OR ( structKeyExists(arguments, "url") AND NOT len(trim(arguments.url)) ) ){
						result.errors = listAppend(result.errors, "URL");
						result.errorsForLog  = listAppend(result.errorsForLog, "url is not valid.");
					
					}

					if( structKeyExists(arguments, "url") AND NOT isValid("URL", arguments.url) ){
						result.errors 		 = listAppend(result.errors, "URL");
						result.errorsForLog  = listAppend(result.errorsForLog, arguments.url & " is not valid.");
					}

					if ( ListLen(result.errors) GT 0 ){
					
						result.error = true;
					
						<!--- url Invalid Input --->
						local.logAction = logAction( actionID = 9001, extra = result.errorsForLog );
						
						return representationOf(result).withStatus(500);

					}else{
					
						result.query = queryNew("profile,profile_custom,profile_Education,profile_Skills,mainbody_image,profilePhoto,bloggerName,bloggerCity,bloggerCountry,blogTitle,blogURL,blogLogo,social_media,membership,press,clients,sponsorships,awards,raveReviwes","varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar");
						
						dom = application.jSoupClass.connect( arguments.url ).userAgent(userBrowser).get();

					    bloggersURL = dom.select('div.forceheight a[href]');
					    industry_details = structNew();

					    for( bloggsURL in bloggersURL ) {

					    	social_links  = "";
						    personal_info = structNew();
						    info_key = ["bloggerName","bloggerCity","bloggerCountry"];
					  		structClear(industry_details);

					  		bloggerProfile 		= application.jSoupClass.connect("#bloggsURL.attr('abs:href')#").userAgent(userBrowser).get();
							// taken from top of the page
							experience 			= bloggerProfile.getElementById('experience');
							profile 	 		= experience.select('span.cfmission').text();
							profile_Education 	= experience.select('div.padleft').eq(2).text();
							profile_custom		= experience.select('div.padleft div.profilecontent a').attr('abs:href');
							skills				= experience.select('div.padleft').eq(4).html()&experience.select('div.padleft').eq(5).html();
							profile_skills		= reReplaceNoCase(skills,'\n<br(>|/>)','|',"all");
							social_media		= bloggerProfile.select('div.profilesocialmedia a[href]');
							mainbody_image		= experience.select('img').attr('abs:src');
							// taken from rightside of the page
							bolggersDetails		= bloggerProfile.select('div.crtan div');
							profilePhoto		= bolggersDetails.select('img').attr("abs:src");
							bloggerInfo 		= bolggersDetails.select('div.profilemaininfoblock span');
							// taken from right bottom of the page
							blog_title			= bloggerProfile.select('div.profilemaininfoblock a span').text();
							blog_URL			= bloggerProfile.select('div.profilemaininfoblock a').attr('abs:href');
							blog_logo			= bloggerProfile.select('div.profilemaininfoblock img').attr('abs:src');
							// taken from industry tab
							industry 			= bloggerProfile.getElementById('industry');
							title 	 			= industry.select('div.cfcattitle');
							
							// get details about the blogger
							for( i=1; i<arrayLen(bloggerInfo); i++ ){
								
								structInsert(personal_info,info_key[i], bloggerInfo.select('span').eq(i-1).text());

							}
							
							// get details for social media links
							for(i=1;i<=arrayLen(social_media);i++){

								social_links = listAppend(social_links,social_media[i].attr('abs:href'),'|');
								
							}
							
							// get data from industry tab
							j=0;

							for( i = 0; i LT arrayLen(title); i++){

								titleData 	= industry.select('div.cfcattitle').eq(i).text();
								bodyOfData	= industry.select('div.profilecontent').eq(j).text();
								
								if( titleData EQ 'CLIENTS' ){

									client_data1 = industry.select('div.profilecontent').eq(j).text();
									
									client_data2 = industry.select('div.profilecontent').eq(++j).text();
									
									bodyOfData	 = client_data1&client_data2;
									
									structInsert(industry_details,titleData,bodyOfData);
								
								} else {						
									
									structInsert(industry_details,titleData,bodyOfData);

								}

								j++;

							}

							queryAddRow (result.query);
							querySetCell(result.query, 'profile', profile);
							querySetCell(result.query, 'profile_custom', profile_custom);
							querySetCell(result.query, 'profile_Education', profile_Education);
							querySetCell(result.query, 'profile_Skills', profile_Skills);
							querySetCell(result.query, 'mainbody_image', mainbody_image);
							querySetCell(result.query, 'profilePhoto', profilePhoto);
							querySetCell(result.query, 'social_media',social_links);
							querySetCell(result.query, 'blogURL', blog_URL);
							querySetCell(result.query, 'blogTitle', blog_title);
							querySetCell(result.query, 'blogLogo', blog_logo);
							querySetCell(result.query, 'bloggerName', structKeyExists(personal_info,'bloggerName') ? structFind(personal_info, "bloggerName") : '');
							querySetCell(result.query, 'bloggerCity', structKeyExists(personal_info,'bloggerCity') ? structFind(personal_info, "bloggerCity") : '');
							querySetCell(result.query, 'bloggerCountry', structKeyExists(personal_info,'bloggerCountry') ? structFind(personal_info, "bloggerCountry") : '');
							querySetCell(result.query, 'membership', structkeyExists(industry_details,'MEMBERSHIPS & AFFILIATIONS') ? structFind(industry_details, 'MEMBERSHIPS & AFFILIATIONS') : '');
							querySetCell(result.query, 'press', structkeyExists(industry_details,'PRESS') ? structFind(industry_details,'PRESS') : '');
							querySetCell(result.query, 'clients', structkeyExists(industry_details,'CLIENTS') ? structFind(industry_details,'CLIENTS') : '');
							querySetCell(result.query, 'sponsorships', structkeyExists(industry_details,'SPONSORSHIPS & ENDORSEMENTS') ? structfind(industry_details,'SPONSORSHIPS & ENDORSEMENTS') : '');
							querySetCell(result.query, 'awards', structkeyExists(industry_details,'AWARDS & ACCOLADES') ? structfind(industry_details,'AWARDS & ACCOLADES') : '');
							querySetCell(result.query, 'raveReviwes', structkeyExists(industry_details,'RAVE REVIEWS') ? structfind(industry_details,'RAVE REVIEWS') : '');
						}
						result.message = application.messages['recipesimport_post_blogs_success'];
						return representationOf(result).withStatus(200);

					}

					break;

				}

			}

		</cfscript>
		
	</cffunction>

	<!--- Method :: PUT --->

	<cffunction name="PUT" access="public" output="false" hint="To make the recipeImport process to complete." auth="true">
		<cfargument name="type" 		type="string"  required="true" >
		<cfargument name="userID" 		type="numeric" 	required="true" >
		<cfargument name="auth_token"  	type="string"  	required="true" >
		<cfargument name="importTaskID" type="numeric"  required="true" >
		<cfargument name="importID"  	type="numeric"  required="false" >
		<cfargument name="recipeID"  	type="numeric"  required="false" >

		<cfset result = structNew() >

		<cfset result['status']  = false >
		<cfset result['message'] = "" >

		<cfscript>

			switch(arguments.type){

				case "completeRecipeImport":{
					
					local.getRecipesImportTask =  application.recipeDataObj.getRecipesImportTask( importTaskID = arguments.importTaskID, userID = arguments.userID );
					
					if( local.getRecipesImportTask.recordcount ){
					
						local.recipeImportTask = application.recipeDataObj.completeRecipeImportTask( importTaskID = arguments.importTaskID, isCompleted = 1 ) ;
						local.recipeImport 	  = application.recipeDataObj.completeRecipeImport( importTaskID = arguments.importTaskID, isParsed = 1 ) ;

						result.status  = true ;
						result.message =application.messages['recipesimport_put_completeRecipeImport_success'] ;
						return representationOf(result).withStatus(200);

					}else{

						result.message = application.messages['recipesimport_put_completeRecipeImport_error'];
						return representationOf(result).withStatus(404);

					}

					break;
				}

				case "updateRecipeID":{

					local.getImportedRecipe = application.recipeDataObj.getImportedRecipe( importID = arguments.importID , importTaskID = arguments.importTaskID );

					if( local.getImportedRecipe.recordcount ){
						
						local.updateRecipeID = application.recipeDataObj.completeRecipeImport( importTaskID = arguments.importTaskID, importID = arguments.importID, recipeID = arguments.recipeID) ;

						result.status  = true ;
						result.message = application.messages['recipesimport_put_updaterecipeid_success'] ;
						return representationOf(result).withStatus(200);

					}else{

						result.message = application.messages['recipesimport_put_updaterecipeid_error'] ;
						return representationOf(result).withStatus(404);

					}

					break;
				}
				
			}
		</cfscript>		

	</cffunction>

	<cffunction name="GET" access="public" returntype="Struct" hint="To get the bending recipe details" output="false" auth="true">
		<cfargument name="userID" 		type="numeric" 	required="true" >
		<cfargument name="auth_token"  	type="string"  	required="true" >

			<cfset result = structNew() >

			<cfset result['status'] = false >
			<cfset result['message'] = "" >			

			<cfset local.recipeImportTask = application.recipeDataObj.getRecipesImportTask( userID = #arguments.userID#, isCompleted = 0 ) >

			<cfif local.recipeImportTask.recordcount >
				
				<cfset result.sourceURL   = local.recipeImportTask.source_url >
				<cfset result.current_row = local.recipeImportTask.current_row >
				<cfset result.total_rows  = local.recipeImportTask.total_rows >

				<cfset result.recipeImportValid = application.recipeDataObj.getImportedRecipe( importTaskID = local.recipeImportTask.importTaskID, userID = arguments.userID, isValid = 1 ) >

				<cfset result.query = application.recipeDataObj.readRecipeImports( importTaskID = local.recipeImportTask.importTaskID )>
				
				<cfset result['status'] = true >
				<cfset result['message'] = application.messages['recipesimport_get_found_success']>
				<cfreturn representationOf(result).withStatus(200)/>

			<cfelse>

				<cfset result['message'] = application.messages['recipesimport_get_found_error']>
				<cfreturn representationOf(result).withStatus(404)/>

			</cfif>

	</cffunction>

</cfcomponent>