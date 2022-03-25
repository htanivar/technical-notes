1. www.angular.io
2. www.madewithangular.com
3. www.luv2code.com/angular-install-guides
4. http://cli.angular.io
5. http://angular.io/guide/file-structure
6. www.getbootstrap.com
7. http://angular.io/api/common#directives
8. http://angular.io/api/common/CurrencyPipe
9. http://angular.io/api/common#pipes

|Term|Definition|
---|---|
| **Component** |  <p>     Main Player in an angular application, which have 2 parts: </br> 1) View for User Interface </br>2) Class that contains application logic / event handling for the view`</p>|
| **View Template** |The User interface for the component </br> Static HTML with dynamic elements|
| **Directive** |Adds custom behavior to HTML Elements </br> Used for looping, conditionals etc|
| **Service** |Helper class that provides desired functionality </br> Retrieving data from a server, performing a calculation, validation etc|
| **Module** |A collection of related componnents directives, services etc|
|**Decorator**|-|
|**Event Binding**|User Events looking into browser events https://developer.mozilla.org/en-US/docs/Web/Events|


|`@Component`| is an Angular Decorator similar to Annotations in Java(selector,templateUrl,styleUrls)|






|Key Files|Purpose|
---|---|
|angular.json|Angular Workspace configuration & List of execution targets|
|e2e directory|End to End testing|
|node_modules directory|Local repo of the node modules|
|package.json|Project meta data list of node dependencies|
|src directory|Main Source code directory|
|src/app directory|App Components, templates ...etc|
|src/assets|Images web assets|
|src/environments|Profiles for environments ex: dev, test, prod..|
|index.html|Main launch page|
|polyfills.ts| Add Supports to different browser versions|
|test.ts|Unit test|
|tsconfig.json|TypeScript compiler configs|



|ng cli commands|Purpose|
---|---|
|`npm install -g @angular/cli`  | Install Angular CLI Globally|
|`ng version`| NG Version|
|`ng help`|NG help|
|`ng serve --open`| deploy web application|
|`ng serve --port 5001 --host 0.0.0.0`| deploy web application on specifi port on remote server|
|`ng new <your-project-name>`| Create a new angular project|
|`ng generate component <required-component-name>`| Create new comonent for the project|
|`ng generate class sales-person-list/SalesPerson`|Create a new Class|
|`npm install bootstrap`|Install Bootstrap via NPM|
|`npm install @fortawesome/fontawesome-free`|Install fortawesome via NPM|

|Angular Commands||
---|---
|*ngFor| For loop|
|*ngIf| If Condition|
|*ngSwitch| switch statement|
|*ngStyle| style|

  
|Router Key Terminology||
---|---
|Router | Main routing service. Enables navigation between views based on user actions.  |  
|Route |Maps a URL Path to the component  |
|RouterOutlet| Acts as a place holder. Renders the desired component based on route |
|RouterLink|Link to specific routes in your application|
|ActivatedRoute| The current active route that is acticated in the component, useful for accessing route parameters |

**app.component.html**


1. index.html is the main file  
2. index.html content is --> <app-root></app-root>
3. Where the <app-root> tag is defined?
   1. app-root is some where defined in a component (probably app.component.ts selector:)


**app.module.ts**

1. The Main Component is here `bootstrap: [AppComponent]`


**Basic Development process**
1. Create a new project
2. Update Main template page
3. Generate new component
4. Add New component selector to app template page
5. Generate a SalesPerson class
6. In SalesPersonListComponent, create same data
7. In sales-person-list template file, build HTML table by looping over data

|Generated Files for Component|Purpose|
 ---|---|
  |sales-person-list.component.ts|The Component Class|
  |sales-person-list.component.html|The Component template HTML|
  |sales-person-list.component.css|The Component private CSS|
  |sales-person-list.component.spec.ts|the unit test specifications|
  |UPDATE src/app/app.module.ts|Adds the component to the main application module|

1. The Main Component is here `bootstrap: [AppComponent]`


**Basic Development process**
1. Create a new project
2. Update Main template page
3. Generate new component
4. Add New component selector to app template page
5. Generate a SalesPerson class
6. In SalesPersonListComponent, create same data
7. In sales-person-list template file, build HTML table by looping over data


**Bootstrap Development process**
1. Get links for remote Bootstrap files
2. Add Links to index.html
3. Apply Bootstrap CSS styles in component template
4. Apply Bootstrap CSS styles in HTML table
5. Update TypeScript components file to reference Bootstrap HTML template


Integrate Online Shopping Template
**Release Plan 2.0**
1. Online Shopping Template Integration
2. Search for Products by Category
3. Searcy for Products by text box
4. Master / Detail view of product
5. Pagination support for products
6. Add Product to shopping cart
7. Shopping cart check out
  
  
  
