# Recipe + Ad Network Site API 
# Code by Roberto Campus

This is an implementation of the TAFFY framework (Coldfusion backend).

It exposes extensive business logic I developed for a website featuring a recipe engine + ad network. The front-end was written in Angular (not included).

Some highlights:

1) Recipe import/parse logic. One of the CFCs (/resources/recipesImport.cfc) contains extensive logic to scrape recipes, particularly from blogs. Most of our end-users were Food bloggers, interested in sharing their recipes to our community of users. The tool business logic includes a fully featured import task, with detailed logging. On the front-end it would show import process to the user, step-by-step, then present a final report and give the user the ability to make edits on all imported records. The recipe parser included logic to process the contents to extract relevant data, including a natural language parser/inflector. API integration with IBM Watson AI platform for image analysis.

2) Social Network integration (Facebook/Twitter). See:
	* /resources/mySocialNetwork.cfc
	* /resources/socialfacebookAuth.cfc
	* /resources/socialFacebookPage.cfc
	* /resources/socialInstagram.cfc
	* /resources/socialInstagramAuth.cfc