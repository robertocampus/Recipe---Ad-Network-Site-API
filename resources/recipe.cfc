<cfcomponent extends="taffyAPI.base" taffy:uri="/recipe/{id}" hint="Using this user can able to <code>Get</code> a single recipe details by passing recipeID. Can also able to <code>Update</code> & <code>Delete</code> an existing recipe using recipeID.">

	<cffunction name="GET" access="public" hint="<code>GET</code> a recipe data using RecipeID" output="false">
		<cfargument name="id" 	  type="numeric" required="true"  hint="Recipe ID (Numeric)">
		<cfargument name="userID" type="numeric" required="false" hint="Current Session UserID.">
		
		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />
  
		<cftry>

			<!--- update Totalview count of a recipe --->
			

			<!--- START:: Getting recipe related details from recipe table --->
			<cfquery datasource="#variables.datasource#" name="result.query" >
			
				SELECT 
					r.recipeID AS 'id',
					r.recipeSlug AS 'slug',
					r.recipeTitle AS 'title',
					r.recipeDesc AS 'description',
					r.recipeSourceURL AS 'source_url',
					r.recipePrepTime AS 'prepare_time',
					r.recipeCookTime AS 'cook_time',
					r.recipeTotalTime AS 'total_time',
					r.recipeTotalServings AS 'total_servings',
					r.recipeTotalIngredients AS 'total_ingredients',
					r.recipeTotalLoves AS 'total_loves',
					evc.count AS 'total_views',
					r.recipeIngredientsPreview AS 'ingredients_preview',
					CONCAT( i.imagePath, '/', i.imageName ) AS 'recipe_FullSize_Image',
					CONCAT( i.imagePath, '/', i.imageThumbFileName ) AS 'recipe_Thumb_Image',
					CONCAT( i.imagePath, '/', i.imageFileNameHalf ) AS 'recipe_mini_Image',
					r.isSponsored,
					r.isprivate,				
					r.recipeRating AS 'ratings',
					v_rd.difficultyName AS 'difficulty',
					u.userID,
					u.userName AS 'authorUserName',
					u.userFirstName AS 'authorFirstName',
					u.userLastName AS 'authorLastName',					
					u.userAbout AS 'authorAbout',
					u.isInfluencer AS 'isInfluencer',
					u.userAddressLine1 AS 'authorAddressLine1',
					u.userAddressLine2 AS 'authorAddressLine2',
					u.userAddressLine3 AS 'authorAddressLine3',
					sp.sponsorID,
					vs.stateName AS 'authorStateName',
					vc.countryFullName AS 'authorCountryName',
					u.userCity AS 'authorCityName',
					CONCAT( ui.imagePath, '/', ui.imageName ) AS 'user_FullSize_Image',
					CONCAT( ui.imagePath, '/', ui.imageThumbFileName ) AS 'user_Thumb_Image',
					CONCAT( ui.imagePath, '/', ui.imageFileNameHalf ) AS 'user_mini_Image',

					( SELECT COUNT(*) FROM recipes WHERE userID =
							 ( 
								SELECT userID FROM recipes 
									WHERE 
									recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
							 ) 
					) AS 'total_UserRecipes'
					,(
						SELECT COUNT(commentID) 
							FROM comments c 
						WHERE c.entityTypeID = 10 							
							AND c.entityID = r.recipeID
							AND c.active  = 1
							AND c.commentStatusID  = 2
					) AS 'total_Comments'
					,(
					SELECT MAX(meta_value)
						FROM users_meta 
					WHERE meta_key = 'users_total_followers' AND userID = u.userID 
					) AS total_followers
					,(
						SELECT MAX(meta_value)
							FROM users_meta 
						WHERE meta_key = 'user_total_posts' AND userID = u.userID 
					) AS total_posts
					,( SELECT COUNT(userID) 
							FROM recipe_madeit 
							WHERE recipeID = r.recipeID 
						) AS 'imadeit'
				FROM recipes r

					LEFT JOIN users 				    u 		ON u.userID   = r.userID
					LEFT JOIN sponsors 				    sp 		ON sp.userID   = u.userID AND sp.active = 1
					LEFT JOIN images 					ui 		ON ui.entityID = u.userID AND ui.entitytypeID = 4

					LEFT JOIN images 					i 		ON i.entityID = r.recipeID AND i.entitytypeID = 10

					LEFT JOIN val_states 			    vs 		ON vs.stateID = u.userStateID
					LEFT JOIN val_countries 		    vc 		ON vc.countryID = u.userCountryID
					LEFT JOIN val_recipe_difficulty 	v_rd 	ON v_rd.difficultyID = r.recipeDifficulty

					LEFT JOIN recipes_directions 		r_dir 	ON r_dir.recipeID = r.recipeID
					LEFT JOIN entityViewsCount evc on evc.entityID = r.recipeID AND evc.entityTypeID = 10

				WHERE r.active = 1
					<cfif NOT structKeyExists(arguments, "userID") OR arguments.userID EQ ''>						
						AND r.isPublished = 1
					<cfelse>
						AND r.userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">
					</cfif>
					AND r.recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				GROUP BY r.recipeID
				
			</cfquery>
			<!--- END:: Getting recipe related details from recipe table --->

			<!--- START:: Getting recipe related details from direction table --->
			<cfquery name="local.direction" datasource="#variables.datasource#" >

				SELECT 	r_dir.id,
						r_dir.directionText,
						r_dir.orderID,
						r_dir.isChecked,						
						CONCAT( img.imagePath, '/', img.imageName ) AS 'direction_FullSize_Image',
						CONCAT( img.imagePath, '/', img.imageThumbFileName ) AS 'direction_Thumb_Image',
						CONCAT( img.imagePath, '/', img.imageFileNameHalf ) AS 'direction_mini_Image'
				FROM recipes_directions r_dir
					LEFT JOIN  images img ON img.entityID = r_dir.id AND img.entityTypeID = 11 
				WHERE r_dir.recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
				ORDER BY r_dir.orderID ASC
					
			</cfquery>

			<cfset result['recipeDirection'] = [] >
			
			<cfloop query="local.direction" >
				<cfset local.recipeDirection = {}>				
				<cfset structInsert(local.recipeDirection,"directionID","#local.direction.ID#")>
				<cfset structInsert(local.recipeDirection,"orderID","#local.direction.orderID#")>
				<cfset structInsert(local.recipeDirection,"isChecked","#local.direction.isChecked#")>	
				<cfset structInsert(local.recipeDirection,"directionText","#local.direction.directionText#")>
				<cfset structInsert(local.recipeDirection,"direction_FullSize_Image","#local.direction.direction_FullSize_Image#")>
				<cfset structInsert(local.recipeDirection,"direction_Thumb_Image","#local.direction.direction_Thumb_Image#")>
				<cfset structInsert(local.recipeDirection,"direction_mini_Image","#local.direction.direction_mini_Image#")>
				<cfset arrayAppend(result.recipeDirection, local.recipeDirection)>
			</cfloop>
			<!--- END:: Getting recipe related details from direction table --->

			<!--- START:: Getting recipe related details from courses table --->
			<cfquery name="local.courses"  datasource="#variables.datasource#" >
				SELECT vr_co.courseID, vr_co.courseName
					FROM val_recipe_course vr_co 
						LEFT JOIN  recipes_course r_co ON vr_co.courseID = r_co.courseID 
					WHERE r_co.recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">					
			</cfquery>

			<cfset result['recipeCourses'] = [] >

			<cfloop query="local.courses" >
				<cfset local.recipeCourses = {}>				
				<cfset structInsert(local.recipeCourses,"courseID","#local.courses.courseID#")>
				<cfset structInsert(local.recipeCourses,"courseName","#local.courses.courseName#")>				
				<cfset arrayAppend(result.recipeCourses, local.recipeCourses)>
			</cfloop>
			<!--- END:: Getting recipe related details from courses table --->

			<!--- START:: Getting recipe related details from Cuisines table --->
			<cfquery name="local.Cuisines" datasource="#variables.datasource#" >
				
				SELECT vr_cu.cuisineID ,vr_cu.cuisineName
					FROM val_recipe_cuisine vr_cu 
						LEFT JOIN  recipes_cuisine r_cu ON vr_cu.cuisineID = r_cu.cuisineID 
					WHERE r_cu.recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
						
			</cfquery>

			<cfset result['recipeCuisines'] = [] >

			<cfloop query="local.Cuisines" >
				<cfset local.recipeCuisine = {}>				
				<cfset structInsert(local.recipeCuisine,"cuisineID","#local.Cuisines.cuisineID#")>
				<cfset structInsert(local.recipeCuisine,"cuisineName","#local.Cuisines.cuisineName#")>				
				<cfset arrayAppend(result.recipeCuisines, local.recipeCuisine)>
			</cfloop>
			<!--- END:: Getting recipe related details from Cuisines table --->

			<!--- START:: Getting recipe related details from Channel table --->
			<cfquery name="local.Channel" datasource="#variables.datasource#" >
				
				SELECT vr_ch.channelID ,vr_ch.channelName
					FROM val_recipe_channel vr_ch 
						LEFT JOIN  recipes_channel r_ch ON vr_ch.channelID = r_ch.channelID 
					WHERE r_ch.recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
						
			</cfquery>

			<cfset result['recipeChannel'] = [] >

			<cfloop query="local.Channel" >
				<cfset local.recipeChannel = {}>				
				<cfset structInsert(local.recipeChannel,"channelID","#local.channel.channelID#")>
				<cfset structInsert(local.recipechannel,"channelName","#local.channel.channelName#")>				
				<cfset arrayAppend(result.recipeChannel, local.recipeChannel)>
			</cfloop>
			<!--- END:: Getting recipe related details from Channel table --->

			<!--- START:: Getting recipe related details from allergy table --->
			<cfquery name="local.allergy" datasource="#variables.datasource#" >
				SELECT vr_al.allergyID ,vr_al.allergyName 
					FROM val_recipe_allergy vr_al 
						LEFT JOIN  recipes_allergy r_al ON vr_al.allergyID = r_al.allergyID
					WHERE r_al.recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">			
			</cfquery>

			<cfset result['recipeAllergy'] = [] >

			<cfloop query="local.allergy" >
				<cfset local.recipeAllergy = {}>				
				<cfset structInsert(local.recipeAllergy,"allergyID","#local.allergy.allergyID#")>
				<cfset structInsert(local.recipeAllergy,"allergyName","#local.allergy.allergyName#")>				
				<cfset arrayAppend(result.recipeAllergy, local.recipeAllergy)>
			</cfloop>
			<!--- END:: Getting recipe related details from allergy table --->

			<!--- START:: Getting recipe related details from diets table --->
			<cfquery name="local.diets" datasource="#variables.datasource#" >
				SELECT vr_di.dietID ,vr_di.dietName 
					FROM val_recipe_diet vr_di 
						LEFT JOIN  recipes_diet r_di ON vr_di.dietID = r_di.dietID 
					WHERE r_di.recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">			
					
			</cfquery>

			<cfset result['recipeDiets'] = [] >

			<cfloop query="local.diets" >
				<cfset local.recipeDiets = {}>				
				<cfset structInsert(local.recipeDiets,"dietID","#local.diets.dietID#")>
				<cfset structInsert(local.recipeDiets,"dietName","#local.diets.dietName#")>				
				<cfset arrayAppend(result.recipeDiets, local.recipeDiets)>
			</cfloop>
			<!--- END:: Getting recipe related details from diets table --->

			<!--- START:: Getting recipe related details from holidays table --->
			<cfquery name="local.holidays" datasource="#variables.datasource#" >
				SELECT vr_ho.holidayID ,vr_ho.holidayName 
					FROM val_recipe_holiday vr_ho 
						LEFT JOIN  recipes_holiday r_ho ON vr_ho.holidayID = r_ho.holidayID
					WHERE r_ho.recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">			
			</cfquery>

			<cfset result['recipeHolidays'] = [] >

			<cfloop query="local.holidays" >
				<cfset local.recipeHolidays = {}>				
				<cfset structInsert(local.recipeHolidays,"holidayID","#local.holidays.holidayID#")>
				<cfset structInsert(local.recipeHolidays,"holidayName","#local.holidays.holidayName#")>				
				<cfset arrayAppend(result.recipeHolidays, local.recipeHolidays)>
			</cfloop>
			<!--- END:: Getting recipe related details from holidays table --->

			<!--- START:: Getting recipe related details from occasions table --->
			<cfquery name="local.occasions" datasource="#variables.datasource#" >
				SELECT vr_oc.occasionID ,vr_oc.occasionName 
					FROM val_recipe_occasion vr_oc 
						LEFT JOIN  recipes_occasion r_oc ON vr_oc.occasionID = r_oc.occasionID 
					WHERE r_oc.recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">			
			</cfquery>

			<cfset result['recipeOccasions'] = [] >

			<cfloop query="local.occasions" >
				<cfset local.recipeOccasions = {}>				
				<cfset structInsert(local.recipeOccasions,"occasionID","#local.occasions.occasionID#")>
				<cfset structInsert(local.recipeOccasions,"occasionName","#local.occasions.occasionName#")>				
				<cfset arrayAppend(result.recipeOccasions, local.recipeOccasions)>
			</cfloop>
			<!--- END:: Getting recipe related details from occasions table --->

			<!--- START:: Getting recipe related details from seasons table --->
			<cfquery name="local.seasons" datasource="#variables.datasource#" >
				SELECT vr_se.seasonID ,vr_se.seasonName 
					FROM val_recipe_season vr_se 
						LEFT JOIN  recipes_season r_se ON vr_se.seasonID = r_se.seasonID
					WHERE r_se.recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">			
			</cfquery>

			<cfset result['recipeSeasons'] = [] >

			<cfloop query="local.seasons" >
				<cfset local.recipeSeasons = {}>				
				<cfset structInsert(local.recipeSeasons,"seasonID","#local.seasons.seasonID#")>
				<cfset structInsert(local.recipeSeasons,"seasonName","#local.seasons.seasonName#")>				
				<cfset arrayAppend(result.recipeSeasons, local.recipeSeasons)>
			</cfloop>
			<!--- END:: Getting recipe related details from seasons table --->

			<!--- START:: Getting recipe related details from ingredients table --->
			<cfquery name="local.ingredients" datasource="#variables.datasource#" >
				SELECT 	r_ingr.ingredientID,
						r_ingr.line_text,
						r_ingr.orderID
					FROM val_recipe_ingredient vr_ingr 
						LEFT JOIN  recipes_ingredientline r_ingr ON vr_ingr.ingredientID = r_ingr.ingredientID
					WHERE r_ingr.recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
					ORDER BY r_ingr.orderID ASC
			</cfquery>

			<cfset result['recipeIngredients'] = [] >

			<cfloop query="local.Ingredients" >
				<cfset local.recipeIngredients = {}>				
				<cfset structInsert(local.recipeIngredients,"ingredientID","#local.Ingredients.ingredientID#")>
				<cfset structInsert(local.recipeIngredients,"line_text","#local.Ingredients.line_text#")>				
				<cfset structInsert(local.recipeIngredients,"orderID","#local.Ingredients.orderID#")>				
				<cfset arrayAppend(result.recipeIngredients, local.recipeIngredients)>
			</cfloop>
			<!--- END:: Getting recipe related details from ingredients table --->			

			<!--- START:: Getting recipe related details from authorBlogDetails table --->
			<cfquery name="result.authorBlogDetails" datasource="#variables.dataSource#" >
								
				SELECT b.blogTitle ,
					b.blogID,
					b.blogSlug
				FROM userblogs ub 
					INNER JOIN blogs b ON ub.blogID = b.blogID 
					WHERE ub.userID = <cfqueryparam value="#result.query.userID#" cfsqltype="cf_sql_integer">

			</cfquery>
			<!--- END:: Getting recipe related details from authorBlogDetails table --->




			<cfif result.query.recordCount EQ 0 >
				<cfset result.message = application.messages['recipe_get_found_success'] />
				<cfreturn noData().withStatus(404) />
			</cfif>

			<cfcatch>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipe/{id}/GET", errorCatch = variables.cfcatch )>	
				<cfset result.message = errormessage(message = 'database_query_error', error = variables.cfcatch)>
			  	<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>
			
		</cftry>

		<!--- //Getting user social details  --->
		<cfset local.userSocialDetails = application.accountObj.getUserSocialDetails(result.query.userID)>

		<cfif local.userSocialDetails.status EQ true>
			<cfset result.userSocialDetails = local.userSocialDetails.dataset>
		<cfelse>
			<cfset result.userSocialDetails = []>
		</cfif>

		<cfset result.status  = true />
		<cfset result.message = application.messages['recipe_get_found_success'] />

	  	<cfset logAction( actionID = 2004, extra = "method: /recipe/{id}/GET" )>

		<cfreturn representationOf(result).withStatus(200) />
	</cffunction>


	<cffunction name="PUT" access="public" output="false" hint="<code>UPDATE</code> an existing recipe data using recipeID">

		<cfargument name = "id"							type="numeric"  required="true" />
		<cfargument name = "recipeTitle"				type="string"   required="false" />
		<cfargument name = "recipeSourceURL"			type="string"   required="false" />
		<cfargument name = "recipeSourceSiteURL"		type="string"   required="false" />
		<cfargument name = "recipeSourceSiteName"		type="string"   required="false" />
		<cfargument name = "recipeExcerpt"				type="string"   required="false" />
		<cfargument name = "recipeDesc"					type="string"   required="false" />
		<cfargument name = "recipePrepTime" 			type="numeric" 	required="false" />
		<cfargument name = "recipeCookTime" 			type="numeric" 	required="false" />
		<cfargument name = "recipeTotalTime"			type="numeric"  required="false" />
		<cfargument name = "recipeTotalServings"		type="numeric"  required="false" />
		<cfargument name = "recipeTotalIngredients"		type="numeric"  required="false" />
		<cfargument name = "recipeIngredientsPreview" 	type="string"   required="false" />
		<cfargument name = "recipeTotalViews"			type="numeric"  required="false" />
		<cfargument name = "recipeTotalLoves"			type="numeric"  required="false" />
		<cfargument name = "recipeRating"				type="numeric"  required="false" />		
		<cfargument name = "imageID"					type="numeric"  required="false" />
		<cfargument name = "userID"						type="numeric"  required="false" />
		<cfargument name = "blogID"						type="numeric"  required="false" />				
		<cfargument name = "recipePublishDate"			type="any"      required="false" />
		<cfargument name = "isDraft"					type="numeric"  required="false" />
		<cfargument name = "isPublished"				type="numeric"  required="false" />
		<cfargument name = "isPending"					type="numeric"  required="false" />
		<cfargument name = "isPrivate"					type="numeric"  required="false" />
		<cfargument name = "isFeatured"					type="numeric"  required="false" />
		<cfargument name = "isReviewed"					type="numeric"  required="false" />
		<cfargument name = "isApproved"					type="numeric"  required="false" />
		<cfargument name = "isRejected"					type="numeric"  required="false" />
		<cfargument name = "active"						type="numeric"  required="false" />
		<cfargument name = "recipeIngredients" 			type="any" 		default="#arraynew()#" />
		<cfargument name = "recipeDirection"			type="any" 		default="#arraynew()#" />
		<cfargument name = "recipeCuisine" 				type="any" 		default="#arraynew()#" />
		<cfargument name = "recipeChannel" 				type="any" 		default="#arraynew()#" />
		<cfargument name = "recipeCourse" 				type="any" 		default="#arraynew()#" />
		<cfargument name = "recipeAllergy" 				type="any" 		default="#arraynew()#" />
		<cfargument name = "recipeHoliday" 				type="any" 		default="#arraynew()#" />
		<cfargument name = "recipeOccasion" 			type="any" 		default="#arraynew()#" />
		<cfargument name = "recipeSeason" 				type="any" 		default="#arraynew()#" />
		<cfargument name = "recipeDiet" 				type="any" 		default="#arraynew()#" />

		<!--- :: init result structure --->	
		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />

		<cftry>
			
			<!--- START:: Updating recipe related details into recipe table --->
			<cfquery datasource="#variables.datasource#" name="local.query" result="isUpdated">
				
				UPDATE recipes
					SET recipeID = recipeID
						
						<cfif structKeyExists(arguments,"recipeTitle") AND len(arguments.recipeTitle)>
							,recipeTitle = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeTitle#" />
							,recipeSlug = <cfqueryparam cfsqltype="cf_sql_varchar" value="#toSlug(arguments.recipeTitle)#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeSourceURL") AND len(arguments.recipeSourceURL)>
							,recipeSourceURL = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeSourceURL#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeSourceSiteURL") AND len(arguments.recipeSourceSiteURL)>
							,recipeSourceSiteURL = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeSourceSiteURL#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeSourceSiteName") AND len(arguments.recipeSourceSiteName)>
							,recipeSourceSiteName = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeSourceSiteName#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeExcerpt") AND len(arguments.recipeExcerpt)>
							,recipeExcerpt = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeExcerpt#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeDesc") AND len(arguments.recipeDesc)>
							,recipeDesc = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeDesc#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipePrepTime") AND len(arguments.recipePrepTime)>
							,recipePrepTime = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipePrepTime#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeCookTime") AND len(arguments.recipeCookTime)>
							,recipeCookTime = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeCookTime#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeTotalTime") AND len(arguments.recipeTotalTime)>
							,recipeTotalTime = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeTotalTime#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeTotalServings") AND len(arguments.recipeTotalServings)>
							,recipeTotalServings = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeTotalServings#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeTotalIngredients") AND len(arguments.recipeTotalIngredients)>
							,recipeTotalIngredients = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeTotalIngredients#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeIngredientsPreview") AND len(arguments.recipeIngredientsPreview)>
							,recipeIngredientsPreview = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.recipeIngredientsPreview#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeTotalViews") AND len(arguments.recipeTotalViews)>
							,recipeTotalViews = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeTotalViews#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeTotalLoves") AND len(arguments.recipeTotalLoves)>
							,recipeTotalLoves = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeTotalLoves#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeRating") AND len(arguments.recipeRating)>
							,recipeRating = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeRating#" />
						</cfif>

						<cfif structKeyExists(arguments,"recipeStrength") AND len(arguments.recipeStrength)>
							,recipeStrength = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.recipeStrength#" />
						</cfif>

						<cfif structKeyExists(arguments,"userID") AND len(arguments.userID)>
							,userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#" />
						</cfif>

						<cfif structKeyExists(arguments,"blogID") AND len(arguments.blogID)>
							,blogID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.blogID#" />
						</cfif>						
						
						<cfif structKeyExists(arguments,"recipePublishDate") AND len(arguments.recipePublishDate)>
							,recipePublishDate = <cfqueryparam cfsqltype="cf_sql_date" value="#arguments.recipePublishDate#" />
						</cfif>
						
						<cfif structKeyExists(arguments,"isDraft") AND len(arguments.isDraft)>
							,isDraft = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isDraft#" />
						</cfif>
						
						<cfif structKeyExists(arguments,"isPublished") AND len(arguments.isPublished)>
							,isPublished = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isPublished#" />
						</cfif>

						<cfif structKeyExists(arguments,"isPrivate") AND len(arguments.isPrivate)>
							,isPrivate = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isPrivate#" />
						</cfif>

						<cfif structKeyExists(arguments,"isPending") AND len(arguments.isPending)>
							,isPending = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isPending#" />
						</cfif>
						
						<cfif structKeyExists(arguments,"isFeatured") AND len(arguments.isFeatured)>
							,isFeatured = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isFeatured#" />
						</cfif>
						
						<cfif structKeyExists(arguments,"isReviewed") AND len(arguments.isReviewed)>
							,isReviewed = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isReviewed#" />
						</cfif>
						
						<cfif structKeyExists(arguments,"isApproved") AND len(arguments.isApproved)>
							,isApproved = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isApproved#" />
						</cfif>
						
						<cfif structKeyExists(arguments,"isRejected") AND len(arguments.isRejected)>
							,isRejected = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.isRejected#" />
						</cfif>
						
						<cfif structKeyExists(arguments,"active") AND len(arguments.active)>
							,active = <cfqueryparam cfsqltype="cf_sql_smallint" value="#arguments.active#" />	
						</cfif>

						,recipeUpdateDate = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#datetimeformat(now(), 'yyyy-mm-dd hh:nn:ss')#" >
					WHERE
						recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

			</cfquery>
			<!--- END:: Updating recipe related details into recipe table --->

			<!--- START: Checking image is changes or not? 
						 If yes then, Calling images endpoint to upload the image into Amazon S3 --->
			<cfif val(arguments.imageID) NEQ 0 >

				<cfset local.getImageDetails = application.dataObj.getImageDetails( entitytypeID = 10, entityID = arguments.id ) >

				<cfif local.getImageDetails.recordCount NEQ 0 >					
					
					<cfset local.imageResponse = httpRequest( methodName = 'DELETE', endPointOfURL = '/image/#local.getImageDetails.imageID#', timeout = 3000 ) />

				</cfif>
				
				<cfset local.attributes.entityID 	= arguments.id />					
				<cfset local.attributes.entityTypeName = 'recipe' />					

				<cfset local.imageResponse = httpRequest( methodName = 'PUT', endPointOfURL = '/image/#arguments.imageID#', timeout = 3000, parameters = local.attributes ) />

			</cfif>
			<!--- END: Checking image is changes or not? 
						 If yes then, Calling images endpoint to upload the image into Amazon S3 --->

			<!--- START:: Updating recipe related details into recipes_ingredientline table --->
			<cfif arrayLen( arguments.recipeIngredients ) >

				<cfquery datasource="#variables.datasource#" name="local.deleteIngredients" result="deletedIngredients" >
					DELETE FROM recipes_ingredientline
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
				</cfquery>

				<cfloop array="#arguments.recipeIngredients#" index="element">

					<cfset local.ingredient 		= application.recipeDataObj.removeSpecialChars(element.ingredient)>
					<cfset local.ingredientDetails 	= application.ingredientParser.parse( local.ingredient.ingredientLine ) >
					
					<cfset local.ingredientID		= application.recipeDataObj.isExistingredientID(ingredientName = local.ingredientDetails.Name )>

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
									<cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">,
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
			<!--- END:: Updating recipe related details into recipes_ingredientline table --->

			<!--- START:: Updating recipe related details into recipes_cuisine table --->
			<cfif arrayLen( arguments.recipeCuisine ) >

				<cfquery datasource="#variables.datasource#" name="local.deleteCuisine" result="deletedCuisine" >
					DELETE FROM recipes_cuisine
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.Cuisine" result="insertCuisine" >

					INSERT INTO recipes_cuisine(
							recipeID,
							cuisineID
							) 
						SELECT #arguments.id#, cuisineID 
								FROM val_recipe_cuisine
								WHERE cuisineName in (
									<cfloop array="#arguments.recipeCuisine#" index="element">
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
										<cfif arrayFindNoCase( arguments.recipeCuisine, element ) NEQ arrayLen( arguments.recipeCuisine )>,<cfelse>);</cfif>
									</cfloop>
				</cfquery>

			</cfif>
			<!--- END:: Updating recipe related details into recipes_cuisine table --->

			<!--- START:: Updating recipe related details into recipeChannel table --->
			<cfif arrayLen( arguments.recipeChannel ) >

				<cfquery datasource="#variables.datasource#" name="local.deleteCuisine" result="deletedCuisine" >
					DELETE FROM recipes_channel
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.Cuisine" result="insertCuisine" >

					INSERT INTO recipes_channel(
							recipeID,
							channelID
							) 
						SELECT #arguments.id#, channelID 
								FROM val_recipe_channel
								WHERE channelName in (
									<cfloop array="#arguments.recipeChannel#" index="element">
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
										<cfif arrayFindNoCase( arguments.recipeChannel, element ) NEQ arrayLen( arguments.recipeChannel )>,<cfelse>);</cfif>
									</cfloop>
				</cfquery>

			</cfif>
			<!--- END:: Updating recipe related details into recipeChannel table --->

			<!--- START:: Updating recipe related details into recipes_course table --->
			<cfif arrayLen( arguments.recipecourse ) >

				<cfquery datasource="#variables.datasource#" name="local.deleteCourse" result="deletedCourse" >
					DELETE FROM recipes_course
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
				</cfquery>					

				<cfquery datasource="#variables.datasource#" name="local.Course" result="insertCourse" >

					INSERT INTO recipes_course(
							recipeID,
							courseID
							) 
						SELECT #arguments.id#, courseID 
								FROM val_recipe_course
								WHERE courseName in (
									<cfloop array="#arguments.recipecourse#" index="element">
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
										<cfif arrayFindNoCase( arguments.recipecourse, element ) NEQ arrayLen( arguments.recipecourse )>,<cfelse>);</cfif>
									</cfloop>									
					
				</cfquery>

			</cfif>
			<!--- END:: Updating recipe related details into recipes_course table --->

			<!--- START:: Updating recipe related details into recipes_allergy table --->
			<cfif arrayLen( arguments.recipeAllergy ) >

				<cfquery datasource="#variables.datasource#" name="local.deleteAllergy" result="deletedAllergy" >
					DELETE FROM recipes_allergy
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
				</cfquery>				

				<cfquery datasource="#variables.datasource#" name="local.Allergy" result="insertAllergy" >

					INSERT INTO recipes_allergy(
							recipeID,
							allergyID
							) 
						SELECT #arguments.id#, allergyID 
								FROM val_recipe_allergy
								WHERE allergyName in (
									<cfloop array="#arguments.recipeAllergy#" index="element">
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
										<cfif arrayFindNoCase( arguments.recipeAllergy, element ) NEQ arrayLen( arguments.recipeAllergy )>,<cfelse>);</cfif>
									</cfloop>									
				</cfquery>

			</cfif>
			<!--- END:: Updating recipe related details into recipes_allergy table --->

			<!--- START:: Updating recipe related details into recipes_holiday table --->
			<cfif arrayLen( arguments.recipeHoliday ) >

				<cfquery datasource="#variables.datasource#" name="local.deleteHoliday" result="deletedHoliday" >
					DELETE FROM recipes_holiday
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.Holiday" result="insertHoliday" >

					INSERT INTO recipes_holiday(
							recipeID,
							holidayID
							) 
						SELECT #arguments.id#, holidayID 
								FROM val_recipe_holiday
								WHERE holidayName in (
									<cfloop array="#arguments.recipeHoliday#" index="element">
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
										<cfif arrayFindNoCase( arguments.recipeHoliday, element ) NEQ arrayLen( arguments.recipeHoliday )>,<cfelse>);</cfif>
									</cfloop>
				</cfquery>

			</cfif>
			<!--- END:: Updating recipe related details into recipes_holiday table --->

			<!--- START:: Updating recipe related details into recipes_occasion table --->
			<cfif arrayLen( arguments.recipeOccasion ) >

				<cfquery datasource="#variables.datasource#" name="local.deleteOccasion" result="deletedOccasion" >
					DELETE FROM recipes_occasion
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.Occasion" result="insertOccasion" >

					INSERT INTO recipes_occasion(
							recipeID,
							occasionID
							) 
						SELECT #arguments.id#, occasionID 
								FROM val_recipe_occasion
								WHERE occasionName in (
									<cfloop array="#arguments.recipeOccasion#" index="element">
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
										<cfif arrayFindNoCase( arguments.recipeOccasion, element ) NEQ arrayLen( arguments.recipeOccasion )>,<cfelse>);</cfif>
									</cfloop>
				</cfquery>

			</cfif>
			<!--- END:: Updating recipe related details into recipes_occasion table --->

			<!--- START:: Updating recipe related details into recipes_season table --->
			<cfif arrayLen( arguments.recipeSeason ) >

				<cfquery datasource="#variables.datasource#" name="local.deleteSeason" result="deletedSeason" >
					DELETE FROM recipes_season
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.Season" result="insertSeason" >

					INSERT INTO recipes_season(
							recipeID,
							seasonID
							) 
						SELECT #arguments.id#, seasonID 
								FROM val_recipe_season
								WHERE seasonName in (
									<cfloop array="#arguments.recipeSeason#" index="element">
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
										<cfif arrayFindNoCase( arguments.recipeSeason, element ) NEQ arrayLen( arguments.recipeSeason )>,<cfelse>);</cfif>
									</cfloop>
				</cfquery>

			</cfif>
			<!--- END:: Updating recipe related details into recipes_season table --->

			<!--- START:: Updating recipe related details into recipes_diet table --->
			<cfif arrayLen( arguments.recipeDiet ) >

				<cfquery datasource="#variables.datasource#" name="local.deleteDiet" result="deletedDiet" >
					DELETE FROM recipes_diet
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.Diet" result="insertDiet" >

					INSERT INTO recipes_diet(
							recipeID,
							dietID
							) 
						SELECT #arguments.id#, dietID 
								FROM val_recipe_diet
								WHERE dietName in (
									<cfloop array="#arguments.recipeDiet#" index="element">
										<cfqueryparam cfsqltype="cf_sql_varchar" value="#element#">
										<cfif arrayFindNoCase( arguments.recipeDiet, element ) NEQ arrayLen( arguments.recipeDiet )>,<cfelse>);</cfif>
									</cfloop>
				</cfquery>

			</cfif>
			<!--- END:: Updating recipe related details into recipes_diet table --->

			<!--- START:: Updating recipe related details into recipes_directions table --->

			<cfif arrayLen( arguments.recipeDirection ) >
				<!--- START: Getting the existing direction ID's --->
				<cfset local.getInitialDirection = application.recipeDataObj.getRecipeDirections( recipeID = arguments.id ) >
				<cfset local.existingRecipeDirectionID = valueList(local.getInitialDirection.id) >
				<cfset local.existingDirection = listToArray( local.existingRecipeDirectionID ) >
				<!--- END: Getting the existing direction ID's --->

				<!--- START: looping over the new recipe direction details --->
				<cfloop array="#arguments.recipeDirection#" index="element">

					<!--- Getting the existing recipeDirection Records with recipeDirectionID --->
					<cfset local.getDirection = application.recipeDataObj.getRecipeDirections( directionID = element.recipeDirectionID ) >
					
					<!--- IF recipeDirection exist making a update Call ELSE making a new insert --->
					<cfif local.getDirection.recordCount GT 0 >

						<cfif arrayFindNoCase( local.existingDirection, element.recipeDirectionID ) >
							<cfset arrayDeleteAt( local.existingDirection, arrayFindNoCase( local.existingDirection, element.recipeDirectionID )) >							
						</cfif>

						<cfquery datasource="#variables.datasource#" name="local.direction" result="insertDirection">

							UPDATE recipes_directions  SET 
								<cfif element.direction NEQ ''>
									directionText = <cfqueryparam value="#element.direction#" cfsqltype="cf_sql_varchar">
								</cfif>
								<cfif element.orderID NEQ ''>
									,orderID = <cfqueryparam value="#element.orderID#" cfsqltype="cf_sql_varchar">
								</cfif>
								<cfif element.imageID NEQ '' AND element.imageID NEQ 0 >
									,imageID = <cfqueryparam value="#element.imageid#" cfsqltype="cf_sql_varchar">									
								</cfif>								

							WHERE

								id = <cfqueryparam cfsqltype="cf_sql_integer" value="#element.recipeDirectionID#">
								AND recipeID = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_numeric">
								
						</cfquery>

						<!--- checking does the recipeDirection image is changed or not?--->
						<cfif val(element.imageid) NEQ 0 >

							<cfset local.getDirectionImage = application.dataObj.getImageDetails( entitytypeID = 11, entityID = element.recipeDirectionID ) >

							<cfif local.getDirectionImage.recordCount NEQ 0 >
								
								<cfset local.imageResponse = httpRequest( methodName = 'DELETE', endPointOfURL = '/image/#local.getDirectionImage.imageID#', timeout = 3000 ) />
								
							</cfif>				

							<cfset local.attributes.entityID 	   = element.recipeDirectionID />				
							<cfset local.attributes.entityTypeName = 'direction' />

							<cfset local.imageResponse = httpRequest( methodName = 'PUT', endPointOfURL = '/image/#element.imageid#', timeout = 3000, parameters = local.attributes ) />

						</cfif>

					<cfelse>

						<cfquery datasource="#variables.datasource#" name="local.direction" result="insertDirection">

							INSERT INTO recipes_directions (

									recipeID,
									directionText,
									orderID,
									imageID,
									isChecked

								) VALUES (

									<cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_numeric">,
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
								
					</cfif>					

				</cfloop>
				<!--- END:: looping over the new recipe direction details --->

				<cfif arrayLen( local.existingDirection ) >

					<cfloop array="#local.existingDirection#" index="directionID">
						
						<cfquery name="local.deleteDirection" datasource="#variables.datasource#">
							DELETE FROM recipes_directions 
								WHERE id = <cfqueryparam cfsqltype="cf_sql_integer" value="#directionID#" >
						</cfquery>

					</cfloop>
					
				</cfif>

			</cfif>
			
			<cfset arguments.recipeStrength = application.scoreObj.getRecipeScore( arguments.id ) >
			<!--- END:: Updating recipe related details into recipes_directions table --->

			<!--- END:: Insert recipe data to related tables--->

			<cfcatch>	
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipe/{id}/PUT", errorCatch = variables.cfcatch )>
				<cfset result.message = errormessage( message = 'database_query_error', error = variables.cfcatch)>
				<cfreturn representationOf(result.message).withStatus(500) />
			</cfcatch>

		</cftry>

		<cfset statusCode = ( isUpdated.recordCount GT 0 ) ? 200 : 404 >
		<cfif statusCode EQ 200 >
			<cfset result.status = true >
			<cfset result.message = application.messages['recipe_put_update_success']>
		<cfelseif statusCode EQ 404 >
			<cfset result.message = application.messages['recipe_put_update_error']>
		</cfif>

	  	<cfset logAction( actionID = 2002, extra = "method: /recipe/{id}/PUT" )>
		
		<cfreturn representationOf(result).withStatus(statusCode) />

	</cffunction>


	<cffunction name="DELETE" access="public" output="false" auth="true" hint="<code>DELETE</code> a recipe data using RecipeID">
		<cfargument name="userID" 		type="numeric" required="true" hint="user ID">
		<cfargument name="auth_token" 	type="string"  required="true" hint="auth_token of the user">
		<cfargument name="id" 			type="numeric" required="true" hint="Recipe ID (Numeric)">

		<cfset var result = StructNew() />
		<cfset result['status']  = false />
		<cfset result['message'] = "" />

		<cftry>

			<cftransaction>
			
				<cfquery datasource="#variables.datasource#" name="local.recipe" result="isDeleted" >

					DELETE FROM recipes
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
						AND userID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.userID#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.ingredientline" >

					DELETE FROM recipes_ingredientline
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.cuisine" >

					DELETE FROM recipes_cuisine
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.channel" >

					DELETE FROM recipes_channel
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.course" >

					DELETE FROM recipes_course
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.allergy" >

					DELETE FROM recipes_allergy
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.holiday" >

					DELETE FROM recipes_holiday
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.season" >

					DELETE FROM recipes_season
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.diet" >

					DELETE FROM recipes_diet
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.directions" >

					DELETE FROM recipes_directions
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.loved" >

					DELETE FROM loved
						WHERE entityID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
						AND entitytypeID = 10

				</cfquery>
				
				<cfquery datasource="#variables.datasource#" name="local.madeit" >

					DELETE FROM recipe_madeit
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.boxes" >

					DELETE FROM recipes_boxes
						WHERE recipeID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">

				</cfquery>

				<cfquery datasource="#variables.datasource#" name="local.image" >

					DELETE FROM images
						WHERE entityID = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
						AND entitytypeID = 10

				</cfquery>

			</cftransaction>

			<cfcatch>
				<!--- // 661, 'Error: Query', 'Error encountered by query', 1 --->
				<cfset logAction( actionID = 661, extra = "method: /recipe/{id}/DELETE", errorCatch = variables.cfcatch )>
	  			<cfset result.message = errorMessage( message = 'database_query_error', error = variables.cfcatch)>

				<cfreturn representationOf(result.messge).withStatus(500) />
				
			</cfcatch>

		</cftry>
		
		<cfset statusCode = ( isDeleted.recordCount GT 0 ? 200 : 404 )>
		
		<cfif statusCode EQ 200 >
			
			<cfset result.status = true>
			<cfset result.message = application.messages['recipe_delete_remove_success']>			
		
		<cfelseif statusCode EQ 404 >

			<cfset result.message = application.messages['recipe_delete_remove_error']>

		</cfif>

	  	<cfset logAction( actionID = 2006, extra = "method: /recipe/{id}/DELETE" )>
		<cfreturn representationOf(result).withStatus(statusCode) />

	</cffunction>


</cfcomponent>