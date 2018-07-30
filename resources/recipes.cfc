<cfcomponent extends="taffyAPI.base" taffy_uri="/recipes/" hint="Using this user can able to <code>Get</code> a list of recipe details. By default pagination used to get twenty records.<br/> <code>Post</code> is used to create a new recipe record.">

	<cffunction name="GET" access="public" hint="Returns a <code>LIST</code> of Recipes Data." output="false">

		<cfargument name="filters" 		type="struct" default="#StructNew()#" required="false" hint="Recipe Listing Filters struct">
		<cfargument name="pagination"	type="struct" default="#StructNew()#" required="false" hint="Recipe Listing pagination struct">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />

		<cfscript>
			// check pagination
			// this normalizes the pagination structure (it might be invalid or missing parameters)
			arguments.pagination = checkPagination(arguments.pagination);

		</cfscript>
  
		<cftry>
		
			<cfquery datasource="#variables.datasource#" name="result.query"> <!--- cachedwithin="#CreateTimeSpan(0,0,5,0)#" ---->
			
				<!--- Step 1: Set Up Temp Table --->
				DROP temporary table if exists _tmp_recipe_search;
				CREATE temporary TABLE _tmp_recipe_search  (  `recipeID` INT(10) UNSIGNED NOT NULL,  PRIMARY KEY (`recipeID`) ) ENGINE=MEMORY;
				 
				<!--- Step 2: Perform Filtering/Search --->
				INSERT INTO _tmp_recipe_search 
				SELECT r.recipeID
				FROM recipes r
				LEFT JOIN sponsors s ON r.userID = s.userID
				WHERE  ( 	1 = 1
							
							<!--- ADD FILTERS TO QUERY  --->
							<cfif StructCount(arguments.filters) GT 0>
							
								<cfloop collection="#arguments.filters#" item="thisFilter">
							 
									<!--- SIMPLE SEARCH on Recipe Title --->	
									<cfif thisFilter EQ "course" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_course WHERE courseID IN ( 
												SELECT courseID FROM val_recipe_course WHERE courseName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)
										
									<!--- AND recipes.recipeTitle LIKE '%#arguments.filters[thisFilter]#%' OR RecipeText LIKE '%#arguments.filters[thisFilter]#%' --->
									<cfelseif thisFilter EQ "cuisine" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_cuisine WHERE cuisineID IN ( 
												SELECT cuisineID FROM val_recipe_cuisine WHERE cuisineName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)

									<cfelseif thisFilter EQ "diet" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_diet WHERE dietID IN ( 
												SELECT dietID FROM val_recipe_diet WHERE dietName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)

									<cfelseif thisFilter EQ "holiday" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_holiday WHERE holidayID IN ( 
												SELECT holidayID FROM val_recipe_holiday WHERE holidayName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)

									<cfelseif thisFilter EQ "occasion" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_occasion WHERE occasionID IN ( 
												SELECT occasionID FROM val_recipe_occasion WHERE occasionName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)
			
									<cfelseif thisFilter EQ "season" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_season WHERE seasonID IN ( 
												SELECT seasonID FROM val_recipe_season WHERE seasonName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)	
										
									<cfelseif thisFilter EQ "allergy" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_allergy WHERE allergyID IN ( 
												SELECT allergyID FROM val_recipe_allergy WHERE allergyName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)
											
									<cfelseif thisFilter EQ "difficulty" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										AND r.recipeDifficulty IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )	

									<cfelseif	thisFilter EQ "userID">
										AND r.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

									<cfelseif thisFilter EQ "sponsorID">
										AND s.sponsorID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

									<cfelseif thisFilter EQ "featured" AND TRIM(arguments.filters[thisFilter]) NEQ "" AND TRIM(arguments.filters[thisFilter])>
										AND r.recipeID IN ( SELECT DISTINCT(entityID) FROM featured 
																WHERE entityTypeID = 10 
																	AND active = 1 
																	AND DATE(featuredDateExpire) > DATE(CURDATE())
															)	
																							
									<cfelseif thisFilter EQ "ingredient" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										AND r.recipeID IN (SELECT DISTINCT(recipeID) FROM recipes_ingredientline 
											WHERE ingredientID IN (SELECT ingredientID FROM val_recipe_ingredient 
												WHERE  ingredientName LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filters[thisFilter]#%">))
									</cfif>
							
								</cfloop>					
									
							</cfif>
							
		                )
						
				AND r.isPublished = 1
				GROUP BY recipeID;
				
				<!--- Step 3: Get Records With Pagination --->
				SELECT 
					r.recipeID AS 'id',
					r.recipeSlug AS 'slug',
					r.recipeTitle AS 'title',
					r.recipeSourceURL AS 'source_url',
					r.recipeTotalTime AS 'total_time',
					r.recipeTotalIngredients AS 'total_ingredients',
					r.recipeTotalLoves AS 'total_loves',
					r.recipeTotalViews AS 'total_views',
					r.recipeIngredientsPreview AS 'ingredients_preview',
					r.recipeStrength,
					CONCAT( i.imagePath, '/', i.imageName ) AS 'recipe_fullsize_image',
					CONCAT( i.imagePath, '/', i.imageThumbFileName ) AS 'recipe_thumb_image',
					CONCAT( i.imagePath, '/', i.imageFileNameHalf ) AS 'recipe_mini_image',
					r.isSponsored,
					r.recipeRating AS 'ratings',
					r.recipeTotalTime AS 'preparation_time',
					u.userName AS 'author_name',
					v_rd.difficultyName AS 'difficulty'

					<cfif structKeyExists(arguments.filters, "lovedUserID") AND TRIM(arguments.filters["lovedUserID"]) NEQ "" AND TRIM(arguments.filters["lovedUserID"]) NEQ 0>
						,( SELECT IF(ISNULL(entityID),'',1) FROM loved 
							WHERE entityTypeID = 10 
								AND userID IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters['lovedUserID']#" list="yes"> ) 
								AND entityID = r.recipeID 
						) AS isLoved
					</cfif>	
					,( 	SELECT GROUP_CONCAT(DISTINCT(vr_co.courseName) SEPARATOR ',')
							FROM val_recipe_course vr_co 
								LEFT JOIN  recipes_course r_co ON vr_co.courseID = r_co.courseID 
							WHERE r_co.recipeID = r.recipeID
						) AS courses 
					,( 	SELECT GROUP_CONCAT(DISTINCT(vr_cu.cuisineName) SEPARATOR ',') 
							FROM val_recipe_cuisine vr_cu 
								LEFT JOIN  recipes_cuisine r_cu ON vr_cu.cuisineID = r_cu.cuisineID 
							WHERE r_cu.recipeID = r.recipeID
						) AS cuisines
					,( 	SELECT GROUP_CONCAT(DISTINCT(vr_ch.channelName) SEPARATOR ',') 
							FROM val_recipe_channel vr_ch
								LEFT JOIN  recipes_channel r_ch ON vr_ch.channelID = r_ch.channelID 
							WHERE r_ch.recipeID = r.recipeID
						) AS channel
					,( 	SELECT GROUP_CONCAT(DISTINCT(vr_al.allergyName) SEPARATOR ',') 
						FROM val_recipe_allergy vr_al 
							LEFT JOIN  recipes_allergy r_al ON vr_al.allergyID = r_al.allergyID
						WHERE r_al.recipeID = r.recipeID
					) AS allergy
					,( 	SELECT GROUP_CONCAT(DISTINCT(vr_di.dietName) SEPARATOR ',') 
						FROM val_recipe_diet vr_di 
							LEFT JOIN  recipes_diet r_di ON vr_di.dietID = r_di.dietID 
						WHERE r_di.recipeID = r.recipeID
					) AS diets
					,( 	SELECT GROUP_CONCAT(DISTINCT(vr_ho.holidayName) SEPARATOR ',') 
						FROM val_recipe_holiday vr_ho 
							LEFT JOIN  recipes_holiday r_ho ON vr_ho.holidayID = r_ho.holidayID
						WHERE r_ho.recipeID = r.recipeID
					) AS holidays
					,( 	SELECT GROUP_CONCAT(DISTINCT(vr_oc.occasionName) SEPARATOR ',') 
						FROM val_recipe_occasion vr_oc 
							LEFT JOIN  recipes_occasion r_oc ON vr_oc.occasionID = r_oc.occasionID 
						WHERE r_oc.recipeID = r.recipeID
					) AS occasions
					,( 	SELECT GROUP_CONCAT(DISTINCT(vr_se.seasonName) SEPARATOR ',') 
						FROM val_recipe_season vr_se 
							LEFT JOIN  recipes_season r_se ON vr_se.seasonID = r_se.seasonID
						WHERE r_se.recipeID = r.recipeID
					) AS seasons
					,( 	SELECT GROUP_CONCAT(DISTINCT(vr_ingr.ingredientName) SEPARATOR ',') 
						FROM val_recipe_ingredient vr_ingr 
							LEFT JOIN  recipes_ingredientline r_ingr ON vr_ingr.ingredientID = r_ingr.ingredientID
						WHERE r_ingr.recipeID = r.recipeID
					) AS ingredients				
					,( SELECT COUNT(userID) 
							FROM recipe_madeit 
							WHERE recipeID = r.recipeID 
						) AS 'imadeit'		
				FROM recipes r			
				
				INNER JOIN (SELECT recipeID FROM _tmp_recipe_search  ORDER BY recipeID ASC LIMIT #arguments.pagination.offset#, #arguments.pagination.limit# ) B ON r.recipeID = B.recipeID
				
				LEFT JOIN loved  l 	ON r.recipeID = l.entityID
				LEFT JOIN users  u 	ON u.userID   = r.userID
				LEFT JOIN images i 	ON i.entityID  = r.recipeID AND i.entityTypeID = 10

				LEFT JOIN  val_recipe_difficulty v_rd ON v_rd.difficultyID = r.recipeDifficulty
				
				GROUP BY r.recipeID;
				
			</cfquery>

			<cfquery datasource="#variables.datasource#" name="local.rows">
				SELECT r.recipeID
				FROM recipes r
				LEFT JOIN sponsors s ON r.userID = s.userID
				WHERE  ( 	1 = 1
							
							<!--- ADD FILTERS TO QUERY  --->
							<cfif StructCount(arguments.filters) GT 0>
							
								<cfloop collection="#arguments.filters#" item="thisFilter">
							 
									<!--- SIMPLE SEARCH on Recipe Title --->	
									<cfif thisFilter EQ "course" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_course WHERE courseID IN ( 
												SELECT courseID FROM val_recipe_course WHERE courseName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)
										
									<!--- AND recipes.recipeTitle LIKE '%#arguments.filters[thisFilter]#%' OR RecipeText LIKE '%#arguments.filters[thisFilter]#%' --->
									<cfelseif thisFilter EQ "cuisine" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_cuisine WHERE cuisineID IN ( 
												SELECT cuisineID FROM val_recipe_cuisine WHERE cuisineName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)

									<cfelseif thisFilter EQ "diet" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_diet WHERE dietID IN ( 
												SELECT dietID FROM val_recipe_diet WHERE dietName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)

									<cfelseif thisFilter EQ "holiday" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_holiday WHERE holidayID IN ( 
												SELECT holidayID FROM val_recipe_holiday WHERE holidayName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)

									<cfelseif thisFilter EQ "occasion" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_occasion WHERE occasionID IN ( 
												SELECT occasionID FROM val_recipe_occasion WHERE occasionName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)
			
									<cfelseif thisFilter EQ "season" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_season WHERE seasonID IN ( 
												SELECT seasonID FROM val_recipe_season WHERE seasonName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)	
										
									<cfelseif thisFilter EQ "allergy" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										
										AND r.recipeID IN ( 
											SELECT DISTINCT(recipeID) FROM recipes_allergy WHERE allergyID IN ( 
												SELECT allergyID FROM val_recipe_allergy WHERE allergyName IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )
											) 
										)
											
									<cfelseif thisFilter EQ "difficulty" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										AND r.recipeDifficulty IN ( <cfqueryparam cfsqltype="cf_sql_string" value="#arguments.filters[thisFilter]#" list="yes"> )	

									<cfelseif	thisFilter EQ "userID">
										AND r.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

									<cfelseif thisFilter EQ "sponsorID">
										AND s.sponsorID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.filters[thisFilter]#">

									<cfelseif thisFilter EQ "featured" AND TRIM(arguments.filters[thisFilter]) NEQ "" AND TRIM(arguments.filters[thisFilter])>
										AND r.recipeID IN ( SELECT DISTINCT(entityID) FROM featured 
																WHERE entityTypeID = 10 
																	AND active = 1 
																	AND DATE(featuredDateExpire) > DATE(CURDATE())
															)	
																							
									<cfelseif thisFilter EQ "ingredient" AND TRIM(arguments.filters[thisFilter]) NEQ "">
										AND r.recipeID IN (SELECT DISTINCT(recipeID) FROM recipes_ingredientline 
											WHERE ingredientID IN (SELECT ingredientID FROM val_recipe_ingredient 
												WHERE  ingredientName LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="%#arguments.filters[thisFilter]#%">))
									</cfif>
							
								</cfloop>					
									
							</cfif>
							
		                )
						
				AND r.isPublished = 1
				GROUP BY recipeID;
			</cfquery>

			<cfset result.rows.total_count = local.rows.recordCount >
			
			<cfcatch>		
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipes/GET", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch )>

				<cfreturn representationOf(result.message).withStatus(500) />	
		  	</cfcatch>
	
  		</cftry>   
		
  		<cfif result.query.recordCount GT 0>

			<cfset result.status  	= true />
			<cfset result.message = application.messages['recipes_get_found_success']>

		<cfelse>

			<cfset result.message = application.messages['recipes_get_found_error']>

  		</cfif>

	  	<cfset logAction( actionID = 2004, extra = "method: /recipes/GET" )>

		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>
	

	<!--- POST method in this component requires user authentication --->
	<cffunction name="POST" access="public" output="false" hint="Used to <code>CREATE</code> a new recipe record." auth="true">

		<cfargument name="recipeData"   type="string"   required="true"   default="" />
		<cfargument name="userID"	    type="numeric"  required="true"   default="" />
		<cfargument name="blogID"	    type="numeric"  required="false"  default="" />		
		<cfargument name="auth_token"   type="string"   required="yes"    hint="User authorization token (auth_token)" />
		<cfargument name="cgi"	 	    type="struct"   required="no"     default="#StructNew()#" hint="CGI vars Structure">		
		<cftry>
			<cfset structAppend( arguments, deserializeJson( arguments.recipeData ) )>


			<cfset result = structNew() >
			<cfset result['error'] = false >
			<cfset result['errors'] = "" >
			<cfset result['errorsforlog'] = "" >

			<cfset result['status']  = false >
			<cfset result['message'] = "" >

			<cfscript>

				param name = "arguments.imageID"				type="any" default="0";			
				param name = "arguments.recipeTitle" 			type="any" default="";
				param name = "arguments.recipeSourceURL" 		type="any" default="";				
				param name = "arguments.recipeSourceSiteURL" 	type="any" default="";
				param name = "arguments.recipeSourceSiteName" 	type="any" default="";
				param name = "arguments.recipeExcerpt" 			type="any" default="";
				param name = "arguments.recipeDesc" 			type="any" default="";
				param name = "arguments.isImported"		 		type="numeric" default="0";
				param name = "arguments.recipePrepTime" 		type="numeric" default="0";
				param name = "arguments.recipeCookTime" 		type="numeric" default="0";
				param name = "arguments.recipeTotalTime" 		type="numeric" default="0";
				param name = "arguments.recipeTotalServings" 	type="numeric" default="0";
				param name = "arguments.recipeStrength" 		type="numeric" default="0";
				param name = "arguments.recipeIngredients" 		type="any" default="#arraynew()#";
				param name = "arguments.recipeDirection"		type="any" default="#arraynew()#";
				param name = "arguments.recipeCuisine" 			type="any" default="#arraynew()#";
				param name = "arguments.recipeChannel" 			type="any" default="#arraynew()#";
				param name = "arguments.recipeCourse" 			type="any" default="#arraynew()#";
				param name = "arguments.recipeAllergy" 			type="any" default="#arraynew()#";
				param name = "arguments.recipeHoliday" 			type="any" default="#arraynew()#";
				param name = "arguments.recipeOccasion" 		type="any" default="#arraynew()#";
				param name = "arguments.recipeSeason" 			type="any" default="#arraynew()#";
				param name = "arguments.recipeDiet" 			type="any" default="#arraynew()#";
				
				param name = "local.recipeSlug" type="string"  default="";

				// flag to identify the recipe called from
				if( NOT structKeyExists(arguments, "isImported") OR ( structKeyExists(arguments, isImported) AND NOT len( trim( arguments.isImported ) ) ) ){
					result['errors'] = listAppend(result['errors'], "isImported");
					result['errorsforlog'] = listAppend(result['errorsforlog'], "isImported: The field isImported is invalid.");
				}

				// verify recipeTitle
				if ( LEN( TRIM( arguments.recipeTitle ) ) EQ 0 ) {
					result['errors'] = listAppend(result['errors'], "recipeTitle");
					result['errorsforlog'] = listAppend(result['errorsforlog'], "recipeTitle: #arguments.recipeTitle#");
				}

				// verify recipeDesc
				if ( LEN( TRIM( arguments.recipeDesc ) ) EQ 0 ) {
					result['errors'] = listAppend(result['errors'], "recipeDesc");
					result['errorsforlog'] = listAppend(result['errorsforlog'], "recipeDesc: #arguments.recipeDesc#");
				}			

				// verify recipeTotalTime
				if ( LEN( TRIM( arguments.recipeTotalTime ) ) EQ 0 AND NOT isValid( "integer", arguments.recipeTotalTime ) ) {
					result['errors'] = listAppend(result['errors'], "recipeTotalTime");
					result['errorsforlog'] = listAppend(result['errorsforlog'], "recipeTotalTime: #arguments.recipeTotalTime#");
				}

				// verify recipeTotalServings
				if ( LEN( TRIM( arguments.recipeTotalServings ) ) EQ 0 AND NOT isValid( "integer", arguments.recipeTotalServings ) ) {
					result['errors'] = listAppend(result['errors'], "recipeTotalServings");
					result['errorsforlog'] = listAppend(result['errorsforlog'], "recipeTotalServings: #arguments.recipeTotalServings#");
				}

				// verify recipeIngredients
				if ( NOT isArray( arguments.recipeIngredients ) ) {
					result['errors'] = listAppend(result['errors'], "recipeIngredients");
					result['errorsforlog'] = listAppend(result['errorsforlog'], "recipeIngredients: #arguments.recipeIngredients#");
				}

			</cfscript>

			<!--- start: any errors? --->
			<cfif ( ListLen(result['errors']) GT 0 )>
				
				<cfset result['error'] = true >
				<!--- Invalid Recipes Input --->
				<cfset local.logAction = logAction( actionID = 55, extra = result['errorsforlog'], cgi = arguments.cgi ) >
			
				<cfreturn representationOf(result).withStatus(406)/>

			<cfelse>


				<cftransaction>

					<!--- START: Insert recipe data to related tables--->
					<cfset local.recipeSlug = toSlug (arguments.recipeTitle) >	

					<!--- Used to get the recipeIngredient Preview data --->
					<cfif structKeyExists(arguments, "recipeIngredients") AND arrayLen( arguments.recipeIngredients )>
						<cfset local.recipeIngredientsPreview = ''>
						<cfloop array="#arguments.recipeIngredients#" index="element">
							<cfset local.recipeIngredientsPreview = listAppend(local.recipeIngredientsPreview, element.ingredient)>
						</cfloop>
					</cfif>					

					<cfquery datasource="#variables.datasource#" name="local.query" result="recipeInsert">
						INSERT INTO recipes(
								recipeSlug,
								recipeTitle,
								recipeSourceURL,
								recipeSourceSiteURL,
								recipeSourceSiteName,
								recipeExcerpt,
								recipeDesc,
								recipePrepTime,
								recipeCookTime,
								recipeTotalTime,
								recipeTotalServings,
								recipeTotalIngredients,
								recipeIngredientsPreview,
								recipeTotalViews,
								recipeTotalLoves,
								recipeRating,
								recipeStrength,
								imageID,
								userID,
								blogID,
								recipeCreateDate,
								isDraft,
								isPublished,							
								isReviewed,
								isApproved,
								isRejected												

							)VALUES(
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#local.recipeSlug#">,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeTitle#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeSourceURL#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeSourceSiteURL#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeSourceSiteName#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeExcerpt#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeDesc#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipePrepTime#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeCookTime#" />,
								<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeTotalTime#" />,
								<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeTotalServings#" />,
								<cfqueryparam cfsqltype="cf_sql_integer" value="#Arraylen(arguments.recipeIngredients)#" />,
								<cfqueryparam cfsqltype="cf_sql_varchar" value="#local.recipeIngredientsPreview#" />,
								<cfqueryparam cfsqltype="cf_sql_integer" value="0" />,
								<cfqueryparam cfsqltype="cf_sql_integer" value="0" />,
								<cfqueryparam cfsqltype="cf_sql_integer" value="0" />,
								<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeStrength#" />,
								<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.imageID#" />,
								<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#" />,
								<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#" />,
								<cfqueryparam cfsqltype="cf_sql_timestamp" value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" >,
								<cfqueryparam cfsqltype="cf_sql_bit" value="1" />,
								<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
								<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
								<cfqueryparam cfsqltype="cf_sql_bit" value="0" />,
								<cfqueryparam cfsqltype="cf_sql_bit" value="0" />

							)
					</cfquery>

					<cfset result['recipeID'] = recipeInsert.GENERATED_KEY >

					<!--- START: Calling images endpoint to upload the image into Amazon S3 --->					
					<cfif arguments.imageID NEQ 0 >
						
						<cfset local.attributes.entityID 	= result.recipeID />					
						<cfset local.attributes.entityTypeName = 'recipe' />					

						<cfset local.imageResponse = httpRequest( methodName = 'PUT', endPointOfURL = '/image/#arguments.imageID#', timeout = 3000, parameters = local.attributes ) />

					</cfif>
					<!--- END: Calling images endpoint to upload the image into Amazon S3 --->

					<cfif structKeyExists(arguments, "recipeIngredients") AND arrayLen( arguments.recipeIngredients )>

						<cfif arguments.isImported EQ 1 >

							<cfloop array="#arguments.recipeIngredients#" index="element">
								<cfset local.ingredientID = 0>

								<cfset	local.ingredient = application.recipeDataObj.removeSpecialChars(element.ingredient)>
								<cfset local.ingredientDetails = application.ingredientParser.parse( local.ingredient.ingredientLine ) >

								<cfif local.ingredientDetails.result>									
									<cfset local.ingredientID		= application.recipeDataObj.isExistingredientID( ingredientName = local.ingredientDetails.Name )>
								</cfif>

								<cfquery datasource="#variables.datasource#" name="local.ingredients" result="insertIngredients" >
								
									INSERT INTO recipes_ingredientline(
											recipeID,
											ingredientID,										
											line_text,
											orderID,
											isMatch
											) VALUES (
												<cfqueryparam cfsqltype="cf_sql_integer" value="#result.recipeID#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#local.ingredientID#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#local.ingredient.ingredientLine#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#element.orderID#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#element.isValid#">
											)						
								</cfquery>			

							</cfloop>

						<cfelse>

							<cfloop array="#arguments.recipeIngredients#" index="element">

								<cfset	local.ingredient = application.recipeDataObj.removeSpecialChars(element.ingredient)>
								<cfset local.ingredientDetails = application.ingredientParser.parse( local.ingredient.ingredientLine ) >
								
								<cfif local.ingredientDetails.result>
									
									<cfset local.ingredientID		= application.recipeDataObj.isExistingredientID( ingredientName = local.ingredientDetails.Name )>
									
									<cfif structKeyExists(local.ingredientDetails, "amount") AND local.ingredientDetails.amount NEQ ''>

										<cfset local.line_amountID		= application.recipeDataObj.getLineAmountValues( amountValue = local.ingredientDetails.amount )>
									
									<cfelse>

										<cfset local.line_amountID		= 0 />

									</cfif>

									<cfif structKeyExists(local.ingredientDetails, "unit") AND local.ingredientDetails.unit NEQ '' >
										
										<cfset local.unitTypeID			= application.recipeDataObj.getunitTypeValues( unitTypeName = local.ingredientDetails.unit )>
									
									<cfelse>

										<cfset local.unitTypeID			= 0 />	

									</cfif>

								<cfelse>

									<cfset local.line_amountID		= 0 />
									<cfset local.unitTypeID			= 0 />	
									<cfset local.ingredientID       = 0 />

									<cfset local.ingredientDetails.Name    = "" />
									<cfset local.ingredientDetails.amount  = 0 />
									<cfset local.ingredient.ingredientLine = element.ingredient>

								</cfif>

								<cfquery datasource="#variables.datasource#" name="local.ingredients" result="insertIngredients" >
								
									INSERT INTO recipes_ingredientline(
											recipeID,
											ingredientID,
											ingredientName,
											line_text,
											line_amountID,
											line_amountText,
											line_unitTypeID,
											orderID,
											isMatch
											) VALUES (
												<cfqueryparam cfsqltype="cf_sql_integer" value="#result.recipeID#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#local.ingredientID#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#local.ingredientDetails.Name#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#local.ingredient.ingredientLine#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#local.line_amountID#">,
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#local.ingredientDetails.amount#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#local.unitTypeID#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#element.orderID#">,
												<cfqueryparam cfsqltype="cf_sql_integer" value="#element.isValid#">
											)						
								</cfquery>			

							</cfloop>

						</cfif>

						

					</cfif>

					<cfif structKeyExists(arguments, "recipeCuisine") AND arrayLen( arguments.recipeCuisine )>

						<cfquery datasource="#variables.datasource#" name="local.Cuisine" result="insertCuisine" >

							INSERT INTO recipes_cuisine(
									recipeID,
									cuisineID
									) 
								SELECT #result.recipeID#, cuisineID 
										FROM val_recipe_cuisine
										WHERE cuisineName in (
											<cfloop array="#arguments.recipeCuisine#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.recipeCuisine, element ) NEQ arrayLen( arguments.recipeCuisine )>,<cfelse>);</cfif>
											</cfloop>
						</cfquery>

					</cfif>

					<cfif structKeyExists(arguments, "recipeChannel") AND arrayLen( arguments.recipeChannel )>

						<cfquery datasource="#variables.datasource#" name="local.style" result="style" >

							INSERT INTO recipes_channel(
									recipeID,
									channelID
									) 
								SELECT #result.recipeID#, channelID 
										FROM val_recipe_channel
										WHERE channelName in (
											<cfloop array="#arguments.recipeChannel#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.recipeChannel, element ) NEQ arrayLen( arguments.recipeChannel )>,<cfelse>);</cfif>
											</cfloop>
						</cfquery>

					</cfif>

					<cfif structKeyExists(arguments, "recipecourse") AND arrayLen( arguments.recipecourse )>					

						<cfquery datasource="#variables.datasource#" name="local.Course" result="insertCourse" >

							INSERT INTO recipes_course(
									recipeID,
									courseID
									) 
								SELECT #result.recipeID#, courseID 
										FROM val_recipe_course
										WHERE courseName in (
											<cfloop array="#arguments.recipecourse#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.recipecourse, element ) NEQ arrayLen( arguments.recipecourse )>,<cfelse>);</cfif>
											</cfloop>									
							
						</cfquery>

					</cfif>

					<cfif structKeyExists(arguments, "recipeAllergy") AND arrayLen( arguments.recipeAllergy )>
						

						<cfquery datasource="#variables.datasource#" name="local.Allergy" result="insertAllergy" >

							INSERT INTO recipes_allergy(
									recipeID,
									allergyID
									) 
								SELECT #result.recipeID#, allergyID 
										FROM val_recipe_allergy
										WHERE allergyName in (
											<cfloop array="#arguments.recipeAllergy#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.recipeAllergy, element ) NEQ arrayLen( arguments.recipeAllergy )>,<cfelse>);</cfif>
											</cfloop>									
						</cfquery>

					</cfif>

					<cfif structKeyExists(arguments, "recipeHoliday") AND arrayLen( arguments.recipeHoliday )>					

						<cfquery datasource="#variables.datasource#" name="local.Holiday" result="insertHoliday" >

							INSERT INTO recipes_holiday(
									recipeID,
									holidayID
									) 
								SELECT #result.recipeID#, holidayID 
										FROM val_recipe_holiday
										WHERE holidayName in (
											<cfloop array="#arguments.recipeHoliday#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.recipeHoliday, element ) NEQ arrayLen( arguments.recipeHoliday )>,<cfelse>);</cfif>
											</cfloop>
						</cfquery>

					</cfif>

					<cfif structKeyExists(arguments, "recipeOccasion") AND arrayLen( arguments.recipeOccasion )>

						<cfquery datasource="#variables.datasource#" name="local.Occasion" result="insertOccasion" >

							INSERT INTO recipes_occasion(
									recipeID,
									occasionID
									) 
								SELECT #result.recipeID#, occasionID 
										FROM val_recipe_occasion
										WHERE occasionName in (
											<cfloop array="#arguments.recipeOccasion#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.recipeOccasion, element ) NEQ arrayLen( arguments.recipeOccasion )>,<cfelse>);</cfif>
											</cfloop>
						</cfquery>

					</cfif>

					<cfif structKeyExists(arguments, "recipeSeason") AND arrayLen( arguments.recipeSeason )>

						<cfquery datasource="#variables.datasource#" name="local.Season" result="insertSeason" >

							INSERT INTO recipes_season(
									recipeID,
									seasonID
									) 
								SELECT #result.recipeID#, seasonID 
										FROM val_recipe_season
										WHERE seasonName in (
											<cfloop array="#arguments.recipeSeason#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.recipeSeason, element ) NEQ arrayLen( arguments.recipeSeason )>,<cfelse>);</cfif>
											</cfloop>
						</cfquery>

					</cfif>

					<cfif structKeyExists(arguments, "recipeDiet") AND arrayLen( arguments.recipeDiet )>

						<cfquery datasource="#variables.datasource#" name="local.Diet" result="insertDiet" >

							INSERT INTO recipes_diet(
									recipeID,
									dietID
									) 
								SELECT #result.recipeID#, dietID 
										FROM val_recipe_diet
										WHERE dietName in (
											<cfloop array="#arguments.recipeDiet#" index="element">
												<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
												<cfif arrayFindNoCase( arguments.recipeDiet, element ) NEQ arrayLen( arguments.recipeDiet )>,<cfelse>);</cfif>
											</cfloop>
						</cfquery>

					</cfif>

					<cfif structKeyExists( arguments,"recipeDirection" ) AND arrayLen( arguments.recipeDirection )>
						
						<cfloop array="#arguments.recipeDirection#" index="element">					
							
							<cfquery datasource="#variables.datasource#" name="local.direction" result="insertDirection">

								INSERT INTO recipes_directions (

										recipeID,
										directionText,
										orderID,
										imageID,
										isChecked

									) VALUES (

										<cfqueryparam value="#result.recipeID#" cfsqltype="cf_sql_numeric">,
										<cfqueryparam value="#element.direction#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#element.orderID#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#element.imageid#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="0" cfsqltype="cf_sql_bit">

									)

							</cfquery>

							<cfif element.imageid NEQ 0 >
						
								<cfset local.attributes.entityID 	   = insertDirection.GENERATED_KEY />				
								<cfset local.attributes.entityTypeName = 'direction' />

								<cfset local.imageResponse = httpRequest( methodName = 'PUT', endPointOfURL = '/image/#element.imageid#', timeout = 3000, parameters = local.attributes ) />

							</cfif>

						</cfloop>

					</cfif>
					<!--- END: Insert recipe data to related tables--->

					<cfset arguments.recipeStrength = application.scoreObj.getRecipeScore( result.recipeID ) >

				</cftransaction>

				<cfset result.status  = true />
				<cfset result.message = application.messages['recipes_post_addnew_success']>

			  	<cfset logAction( actionID = 2000, extra = "method: /recipes/POST" )>

				<cfreturn representationOf(result).withStatus(200) />
				
			</cfif>		

			<cfcatch>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipes/POST", errorCatch = variables.cfcatch )>
				<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>

				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>

		</cftry>
			 
		
	</cffunction>

</cfcomponent>