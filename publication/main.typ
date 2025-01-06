#import "ilm.typ": *
#import "@preview/xarrow:0.3.0": xarrow, xarrowSquiggly, xarrowTwoHead
#import "@preview/equate:0.2.1": equate

// for definition and example subheadings
#import "@preview/great-theorems:0.1.1": *
#import "@preview/rich-counters:0.2.2": *

// for listings
#import "@preview/codly:1.1.1": *
#show: codly-init.with()
#codly(languages: (
  HTML: (
    name: "SPARQL", color: green
  )
))

// for ER-Diagrams
#import "@preview/pintorita:0.1.3"

#set text(lang: "en", region: "GB")
#show: great-theorems-init
// #show raw.where(lang: "pintora"): it => pintorita.render(it.text) // todo: Add this back in when I want to print.

// set the width of images in the whole document
#set image(width: 360pt)

#let spct = sym.space.punct
#show "e.g.": [e.#sym.space.thin\g.] // unsure whether I like this.
#show "i.e.": [i.#sym.space.thin\e.]
#show "B.Sc.": [B.#spct\Sc.]
#show "M.Sc.": [M.#spct\Sc.]
#show "Prof. Dr.": [Prof.#spct\Dr.]

#let assessor = [Prof. Dr. Clemens Beckstein\ M. Sc. Johannes Mitschunas]
#let degree = [Bachelor of Science (B. Sc.)]

#show: ilm.with(
  title: [Query by Graph],
  author: "Friedrich Answin Daniel Motz",

  // cover-german: (
  //   faculty: "Fakultät für Mathematik und Informatik",
  //   university: "Friedrich-Schiller-Universität Jena",
  //   type-of-work: "Bachelorarbeit",
  //   academic-degree: degree,
  //   field-of-study: "Informatik",
  //   author-info: "15. Juli 2001 in Chemnitz, Deutschland",
  //   assessor: assessor,
  //   place-and-submission-date: "Jena, 12. Januar 2025",
  // ),

  cover-english: (
    faculty: "Faculty for Mathematics and Computer Science",
    university: "Friedrich Schiller University Jena",
    type-of-work: "Bachelor Thesis",
    academic-degree: degree,
    field-of-study: "Computer Science",
    author-info: "15 July 2001 in Chemnitz, Germany",
    assessor: assessor,
    place-and-submission-date: "Jena, 12 January 2025",
  ),
  
  abstract: [
    I propose a collection of tools for building and running SPARQL queries for complex RDF databases with the support of formal ontologies, which are neatly composed into one and given the name Query by Graph. #todo[Rephrase and add]
  ],
  
  preface: align(left)[
    #todo[
      Write a heartwarming preface.
      - mention Olaf Simons for the idea in his blog post
      - mention Lucas Werkmeister for his assistance on technical details on Wikibase
      - mention C. B. and J. M. for their mentoring
      - mention Patrick Stahl for his work on the thesis
    ] 
  ],
  
  appendix: [
    #set heading(outlined: false)
    #heading(numbering: none, "Use of Generative AI")
    This bachelor thesis was written in assistance of the OpenAI large language models GPT-4o and GPT-o1 preview. The large language models were used to ease literature research and to point out stylistic, orthographical and grammatical mistakes to the writer.
  ],
  
  abbreviations: (
    ("W3C", "World Wide Web Consortium (registered trademark)"),
    ("RDF", "Resource Description Framework"),
    ("RDFS", "Resource Description Framework Schema (Ontology within RDF)"),
    ("SPARQL", [SPARQL Protocol And RDF Query Language (see @heading:sparql)]),
    ("IRI", [Internationalised Resource Identifier (see @heading:iri)]),
    ("BGP", [Basic Graph Pattern (@def:bgp)]),
    ("OWL", "Web Ontology Language"),
    ("VQG", [Visual Query Graph (see @def:vqg)]),
    ("VQL", "Visual Query Language"),
    ("qVQG", [qualifiable Visual Query Graph (see @def:qvqg)]),
    ("WASM", [Web Assembly]),
    ("API", "Application Programming Interface"),
    ("WWW", "World Wide Web")
  ),

  external-link-circle: true, // TURN THIS OFF IF YOU GENERATE THE PRINT VARIANT
  
  figure-index: (enabled: true),
  table-index: (enabled: true),
  listing-index: (enabled: true),
  bibliography: bibliography(title: "Bibliography", style: "ieee", "bib.yaml")
)

/* BEGIN Custom Environment */

#let mathcounter = rich-counter(
  identifier: "mathblocks",
  inherited_levels: 1
)

#let definition = mathblock(
  blocktitle: "Definition",
  counter: mathcounter
)

#let theorem = mathblock(
  blocktitle: "Theorem",
  counter: mathcounter,
)

#let lemma = mathblock(
  blocktitle: "Lemma",
  counter: mathcounter,
)

#let example = mathblock(
  blocktitle: "Example",
  counter: mathcounter,
)

#let remark = mathblock(
  blocktitle: "Remark",
  prefix: [_Remark._],
  // inset: 5pt,
  // fill: lime,
  // radius: 5pt,
)

#let proof = proofblock()

#let note(it) = text(fill: luma(150), size: 0.7em, it)
#let spruch(it) = move(dx: -30pt, text(style: "italic", fill: luma(100), quote(it)))

#let longArrow = xarrow.with(
  sym: sym.arrow.long,
  width: 5em,
  partial_repeats: false,
)

#show: equate.with(breakable: true, sub-numbering: true)
#set math.equation(numbering: "(A.1)", supplement: "Eq.")

#set heading(numbering: "1.1")
#set quote(block: true)

#show heading.where(level: 1): it=> [#v(.5cm) #it #v(.2cm)]
#show heading.where(level: 2): it=> [#v(.5cm) #it #v(.2cm)]

#show raw: set text(
  font: "Noto Sans Mono",
  weight: 300,
  ligatures: true,
  discretionary-ligatures: true,
  historical-ligatures: true,
)

/* END Custom Environment */

= Aim and Relevance <heading:introduction>
/*#todo[

Contents of Aim and Relevance
- Context: make sure to link where your work fits in
- Problem: gap in knowledge, too expensive, too slow, a deficiency, superseded technology
- Strategy: the way you will address the problem  

I should also state some general information:
- comment on employed hardware and software
- describe methods and techniques that build the basis of your work
]*/

== Background <problem_heading>
#todo[Die 10 Sätze, die ich gestern Nacht zu Felix gesagt habe.]

Over its thousands of years in existence, humanity has built an _infrastructure for knowledge_. It started with stone tablets, evolved to hand-written papyrus books, libraries, the printing press and most recently computers and the internet. Instead of using a library or asking a colleague, we usually consult search engines, for even small questions. With them, the need to supply data in a computer interpretable format arose. This lead to the inception of a platform called Wikidata, which arose as a "machine-readable" version of Wikipedia. Wikidata has become a form of library, in which the knowledge is not written in human, but machine language. Now, the new challenge has become to retrieve information from this new library. Our librarian can only help us to find certain entries. To find the connection between information snippets from these entries is still the readers task. For this, users can write database queries in a special query language.

== This Work
#todo[Dieses Kapitel sollte kontextfrei verständlich sein.]

This thesis aims to lay the ground work for a visual query builder for SPARQL queries.My developed program _Query by Graph_#footnote[A demonstration is available at https://quebyg.danielmotz.de/.] allows the user to build queries for Wikibase instances (e.g. Wikidata) without the necessity to write code. The idea is, that the contents of a Wikibase instance and the query for the same can be visualised as a graph, consisting of nodes and edges between them. Using _Query by Graph_, the user can build a graph of a desired structure, fill in variables for unknown structures and retrieve the query's result from any Wikibase instance. Novel to current work, it can *import a previously built query* and *apply changes from the generated SPARQL query to the visual query graph*. Furthermore, the user can work with _multiple Wikibase instances_ in one session, allowing for *federated queries*. Furthermore, in practical application of RDF, certain constructs occur, which are supposed to interpreted in a certain way. This work shows, that these can also be mapped to a visual query graph. #todo[sollte ich hier nun den Begriff Qualifier erwähnen? Das könnte man übrigens nicht nur für Qualifier machen, sondern analog für ordered lists, references, ...] 

#figure(
  image("screenshot.png"),
  caption: [A screenshot of the current state of the program]
)

== Related Work
Main inspiration for this work was a blog entry by Olaf Simons, called *"You should be able to graphically search in a graph database"* @Simons_Blog_Entry_Graphic_query, where he describes a visual query interface, which models the structure of the RDF graph it is trying to query. The user can create nodes and draw edges between them, where the edges relate to Wikibase properties and nodes to items. Simons makes an interesting addition to the graphical repertoire, which are qualifiers. A qualifier can add additional information to a property between to items, for example, the relationship `educated-at` could be qualified by the two statements `from 2020` and `to 2023`. In Wikibase, a user can define arbitary properties to be qualifying of a relationship and is not limited to statements about time, like in this example. The RDF graph structure necessary is, however, not intuitive, as it involves implicit nodes. Simons proposes the simple graphical element, to draw additional edges from the qualified edge, making querying for qualifiers using a graphical tool manageable in the first place.

The approach by Vargas et al. @Vargas2019_RDF_Explorer called *RDF Explorer* is to build a query for a Wikibase instance, starting from a single entry/item. It shows all possible assertions for this item to build the query. The goal is to guide the formulation of the user's question from a known starting point to the wanted result. The software is called RDF Explorer#footnote[A demonstration is available at https://rdfexplorer.org.] and works with one Wikibase instance at a time. It offers example queries, which can be dragged to the graph building pane. Their work aims to allow the user to build a query, but also discover what the data source has to offer at the same time.

*Sparnatural* @Sparnatural allows to build queries using an interface similar to block-based visual programming languages. It works for arbitrary RDF data sources, not just Wikibase. However, it requires an ontology to generate the categories and options in the user interface. Anything not covered by the ontology, cannot be asked for in a built query. Still, the implementation is very advanced and offers many of the language features of SPARQL, i.e. `FILTER` statements.

*SPARQLVis* @SPARQLVis proposes a form-based interface and promises features such as a preview of all related entities to an item and the same querying functionalities as the other here mentioned approaches. The work contains screenshots of the program, which show a relatively complicated interface for the same functionality offered by others (e.g. Vargas).

#todo[irgendwo anders unterbringen:]
Query by Graph lays the to focus on graph-based query building, like RDF Explorer, because the user can discover the data offered in a Wikibase instance by using the already existing web-interfaces. They are by design adequate to the modeled data. The advantage to have a discovery function integrated with the query builder is obvious, however, only small. The possible assertions for an elaborated item are large and their suggestion can lead to confusion. A query builder's main tasks are to enable the user to quickly find entities the user knows of, write potent queries using an intuitive visualisation and to generate a SPARQL query.


/*Much of the mankind's knowledge is stored in the format of natural language, which can not be accessed without following these steps: 1. rough research on a topic, 2. formulate a question, 3. finding relevant literature to the question, 4. reading the literature, 5. extracting the relevant facts, (optional: 6. rephrasing the question because you now know what you were actually asking for) and, finally, 7. inferring an answer from the retrieved facts. This process can be tedious, but, gladly, many of these steps have been facilitated by generations before us. May it be in the form of letterpress, libraries, a librarian, the world wide web (WWW), a search engine and so forth --- we can rely on an _infrastructure for knowledge_.
 
The present internet search engines use a refined mix of network and metadata analysis as well as natural language processing (NLP) to identify the most relevant results to a topic. The World Wide Web also includes large websites like Wikipedia, which, similar to a printed encyclopedia, provide information in natural language. Depending on the topic being discussed, an entry usually shows a certain structure. Entries about individuals typically include their dates of birth and death, while entries about monuments most commonly provide information about their architect, location, and year of construction, among other details. The fundamental idea of _Wikibase_#footnote[https://wikiba.se/, also note that there were similar approaches, such as #link("https://en.wikipedia.org/wiki/Freebase_(database)")[Freebase]] is to enable the user to strictly formalise such semi-structured articles, so that its contents are annotated to be machine-readable.

The idea of formalising knowledge is not new. The field of formal ontology revolves around the creation of theories on how to model an arbitrary domain, such as the world we live in. One concrete formal ontology defines a theory about the workings of a concrete domain. It allows for the definition of i.e. names, categories, properties and relationships between any of those. The use of ontologies presents a two-fold advantage: Any statement within an ontology is expressed in clearly interpretable terms, because it can be viewed independently of any natural language constructs. The difficulty with formal ontologies, however, is anticipating all (or at least most) things and relations that need to be represented in advance. Therefore, ontologies require careful deliberation and their genesis usually goes by the saying: "Many cooks spoil the broth". In contradiction, collaboration between domain experts and ontology engineers is an existential necessity.

_So, how could this resource-consuming process be in parts avoided or supported, whilst not giving up the advantages of computer-processability?_ Originally conceptualised by Tim Berners-Lee, the W3C#sym.trademark.registered standardised the Resource Description Framework (RDF). While an ontology consists of a theory (T-Box) and assertions (A-Box, which are statements compliant with the theory), an RDF knowledge base can consist solely of an A-Box -- the T-Box is quietly implicit. Using an RDF schema, a taxonomy can be added (at any time), usually using an "instance-of" assertion, but consistency is no inherent obligation of an RDF database#footnote[although it is obviously good practice to be consistent with the RDF schema].

This "formalise as you go"-approach allows for maximal flexibility of the data model and proves advantageous, e.g. in the digital humanities. Recently, historians, among others, started to use centralised knowledge bases, allowing for collaboration on research questions and finding connections between the results from different researchers. A grand initiative called FactGrid#footnote[http://factgrid.de] hosts a free-to-use Wikibase instance tailored for the digital humanities, in the hope of creating synergy effects for future research.*/

/*
== Problem


This directly leads to the relevance of this work: Wikibase is a popular software for community knowledge bases and is RDF compatible. Such RDF databases#footnote[Technically, Wikibase uses a different internal representation and only maps to the RDF standard. @fig:rdf_mapping gives an overlook over the mapping.], however, can only be potently queried using a query language called SPARQL. Most researchers in the humanities will not find the time to study such arbitrary technicalities in-depth. The idea for this thesis comes from a blog post by Olaf Simons @Simons_Blog_Entry_Graphic_query on the allure of a visual query interface. The user should be 

I reviewed several visual query helpers @Vargas2019_RDF_Explorer @KnowledgeGraphExplorationForLaypeople @Sparnatural and found them to have room for improvement in routine use and expressiveness. The aim of this work is to lay the groundwork for a visual query builder, which enables a previously unintroduced user to create complex SPARQL queries on Wikibase instances in daily use.

An important example are *qualifiers*, which are widely used in Wikibase instances to further specify a relationship between individuals. For example, a statement such as "Goethe was educated at the University of Leipzig #underline[from 1765 to 1768]" can be modelled as three assertions:
(1) Goethe was educated at the University of Leipzig, (2) this education started in 1765 and (3) it ended in 1768. The underlined part of above expression form two *qualifiers*. As this structure is commonly used in Wikibase, Olaf Simons proposes a visualisation of such qualifiers, which can not yet be found in current implementations.


/*
Most factual knowledge can easily be written in terms of relations between individuals.

#todo[
  Therefore challenges are:
  - Making information in an RDF databases understandable and not so abstract for a human interpreter (for example visualising the result in a graph)
]

#todo[Connect the following to somewhere:]

RDF databases store large amounts of validated data and are freely available, however, they:
- can only be potently queried using SPARQL, which is not intuitive for non-programmers,
- can be looked at using several interfaces, which however lack inference capabilities,
- usually contain no formal ontology to inference on their data,
- can hardly automatically be made consistent with a formal ontology and
- allow for no systemic consistency checks (i.e. those have to be ran as post-hoc batch jobs).*/
*/
/*
== Proposed Solution
This thesis aims to explore methods and concrete implementation, which guides the user through the process of finding an answer to a given question in a Wikibase knowledge base. This includes:

- enabling a layman to create complex SPARQL SELECT-queries using a visual interface and

- allow changes to the SPARQL SELECT-query, which will in turn change the graph in the visual interface.

It will use Wikibase-specific features and conventions, such as:
- the fuzzy search API,

- the meta-info API and

- RDF constructs, i.e. Qualifiers (see @heading:qualifiers).

The concrete enhancements over other approaches are: #todo[Move this to the Results section?]

- *higher user-satisfaction* compared to similar visual query builders, such as @Vargas2019_RDF_Explorer, as #todo[write limited user study and name more query builders]

- the ability to create queries over *multiple Wikibase data sources*,

- *importing* existing SPARQL queries,

- *editing* the query and associated graph using an *integrated code editor*

- #todo[list more :-)]

For this, I decided to develop a lightweight web application, which at its heart has Rust-code to translate visually built queries to SPARQL queries and vice versa#footnote[The code is publicly available at #link("https://github.com/HerrMotz/bachelor-thesis/")[`http://github.com/HerrMotz/bachelor-thesis`].] (see @heading:implementation). The program is already in practical application at the time of writing. Changes to the code have been made by a team from the digital humanities at the Friedrich Schiller University Jena under my lead, where a hands-on session with students was conducted. Any changes which do not originate from my work are clearly marked in the code repository. #todo[lasse ich das wirklich so stehen?]


#todo[Why should a user be able to edit the query? What sense does this make?
- can be used to import an existing query
- some users can maybe write some parts of a SPARQL query and should have the possibility to do so.
- pasting parts from another query is also very useful
]*/

/*
== Related Work

#set heading(outlined:false)
=== RDF Explorer <heading:rdf_explorer>

The approach by Vargas et al. @Vargas2019_RDF_Explorer is to show all possible assertions about an item already while building the query. The goal is to guide the formulation of the user's question from a known starting point. This approach uses a fuzzy search prompt for an RDF resource as a starting point. After adding an object from the prompt results to the drawing board, the user can select from a list of all relations to other objects to augment the prompt. The user may also leave the relation unspecified, add a new object and select from a list of all assertions between these two objects. A user may just as well choose to let any object or property be a variable.

#example[
  The _Wikidata_ object `wd:Q5879`, also known as _Johann Wolfgang von Goethe_, offers several possible assertions, such as that he is "instance of" human and that he was "educated at" the University of Leipzig. This approach shows these in a sidebar, implying that those might be sensible next steps to specify a question.
]

Compared to writing a complex query manually, this approach offers feedback on which queries may yield a result. The user does not even need to run the generated SPARQL query, because the result is already clear from the explorer interaction.

#todo[Olaf Simons was puzzled, which sense it makes to run the SPARQL query afterwards, because the result is already clear from the interaction.]

A demonstration is available at https://rdfexplorer.org.

=== Exploring KGs (also Vargas)
@Vargas2020_UI_for_Exploring_KGs
#todo[
  Summarise
]

=== RDF2Graph
This approach by van Dam et al. @vanDam2015_RDF2Graph conceptualises special RDF resources, which contain _class_ and _subclass_ assertions for its objects. From this information a network of classes can be extracted, which can be used to visualise the possible relations between instances of classes in the resource. This approach was proven to be useful for resources on biology, e.g. #link("https://www.ebi.ac.uk/chebi/")[ChEBI] and #link("https://sapp.gitlab.io/docs/index.html")[SAPP]. Unfortunately, the approach does not discuss the modelling challenges for resources with incomplete, inconsistent or missing class relations.

=== NLQxform
https://www.semanticscholar.org/paper/NLQxform%3A-A-Language-Model-based-Question-to-SPARQL-Wang-Zhang/159ee26c0c2666b3e18814857b4a4d4182ed8246

=== Smeagol: A "Specific-to-General" Query Interface Paradigm

=== Obi-Wan: Ontology-Based RDF Integration of Heterogeneous Data


=== Knowledge Graph Exploration for Laypeople
@KnowledgeGraphExplorationForLaypeople
#todo[Summarise]


=== Conceptual Navigation in Large Knowledge Graphs 
@ConceptualNavigationInLargeKnowledgeGraphs
#todo[Summarise]

=== Connecting Ontologies and RDF Databases 
@Arakawa2023_SugarBindRDFOntology
#todo[Summarise]

=== Relevant Takeaways
Visual Interfaces seem to be promising advantages in the research community and are relevant.
#todo[Build a bridge between related work and my work]

#todo[Make the summaries of other papers more concise, so that it can be put into one running text]

#set heading(outlined:true)
*/

= Preliminaries <heading:fundamentals>
/*#todo[

Questions, which I would like to be answered in this chapter:
- How can information about the real world be represented in a computer? #sym.checkmark
- What are RDF databases in comparison to other semantic technologies? #sym.checkmark
- What is the advantage of using a strict formal ontology in comparison to an RDF database? #sym.checkmark
]*/

Computers generally lack information about the environment humans live in. For example, unless formalised, a computer is unaware of the fact, that an arbitrary arrangement of numerals separated by lines, such as `8/7/2000`, is supposed to represent a date within a calendar based on the birth of a religious figure. How would a human even know of this convention, if it were not taught to him? And even with this knowledge, one can easily stumble upon a false friend: Here, I picture a European fellow confronted with an American booking confirmation. The American interprets the above date as August 7th in the year 2000. In the worst case, the European confidently interprets it as July 8th and would probably be wrong. Explicating the date format would have prevented this disaster.

#todo[
  Hier wir noch nicht deutlich, was der eigentliche Grundgedanke hinter semantischen Technologien eigentlich ist. Diese Sektion sollte ich gründlich überarbeiten, da Prof. B. sie genau lesen wird.
]

This motivated the introduction of _Semantic Technologies_ to the web. The original idea by Tim Berners-Lee was to annotate web pages using a well-defined common vocabulary, so that any computer can, without human assistance, extract the relevant contents of a website. For example, a doctors office might post opening times on their website. Using a public vocabulary, the website describes a table as "opening times" and the strings of weekdays and times as entries of the opening times. A program could fetch the HTML source, read the RDFa annotations and use them to present a list of opening times in a list of search results. This approach would not require pattern matching or statistics to come to a definitive result. These deliberations waged the establishment of standards, such as 
the Resource Description Framework (see @heading:rdf_standard) and Ontology Web Language. Today, these standards are hardly used to annotate websites, but to build semantic networks, such as DBpedia or Wikidata.

The idea of formalising knowledge is not new. The field of *formal ontology* revolves around the creation of theories on how to model an arbitrary domain, such as the world we live in. One concrete formal ontology defines a theory about the workings of a concrete domain. It allows for the definition of i.e. names, categories, properties and relationships between any of those. The use of ontologies presents a two-fold advantage: Any statement within an ontology is expressed in clearly interpretable terms, because it can be viewed independently of any natural language constructs. The difficulty with formal ontologies, however, is anticipating all (or at least most) things and relations that need to be represented in advance. Therefore, ontologies require careful deliberation and their genesis usually goes by the saying: "Many cooks spoil the broth". In contradiction, collaboration between domain experts and ontology engineers is an existential necessity.

_So, how could this resource-consuming process be in parts avoided or supported, whilst not giving up the advantages of computer-processability?_ Originally conceptualised by Tim Berners-Lee, the W3C#sym.trademark.registered standardised the Resource Description Framework (RDF). While an ontology consists of a theory (T-Box) and assertions (A-Box, which are statements compliant with the theory), an RDF knowledge base can consist solely of an A-Box -- the T-Box is quietly implicit. Using an RDF schema, a taxonomy can be added (at any time), usually using an "instance-of" assertion, but consistency is no inherent obligation of an RDF database#footnote[although it is obviously good practice to be consistent with the RDF schema].

This "formalise as you go"-approach allows for maximal flexibility of the data model and proves advantageous, e.g. in the digital humanities. Recently, historians, among others, started to use centralised knowledge bases, allowing for collaboration on research questions and finding connections between the results from different researchers. A grand initiative called FactGrid#footnote[http://factgrid.de] hosts a free-to-use Wikibase instance tailored for the digital humanities, in the hope of creating synergy effects for future research.

== RDF Standard <heading:rdf_standard>
The W3C#sym.trademark.registered recommends a standard for exchange of semantically annotated information called the Resource Description Framework (RDF) standard model. The most notable recommendations are

- the RDF graph format and triples (see @heading:triples),

- the Internationalised Resource Identifier (@heading:iri) and

- the query language SPARQL (see @heading:sparql).

This chapter introduces the parts of the recommendation which are relevant to this work and builds a bridge to concrete conventions around RDF, i.e. Wikibase. 

/*
#todo[
- What are alternatives to RDF databases?
- How do RDF databases work?
- Which query languages work / are used on RDF databases?
]

#todo[
  Important resource: https://www.mediawiki.org/wiki/Wikibase/Indexing/RDF_Dump_Format#Prefixes_used
]
*/

=== Graphs and Triples <heading:triples>

#definition[
  Let *$I$* denote the set of IRIs (see @heading:iri), *$B$* denote the set containing all blank nodes, *$L$* denote the set of literals (see @heading:literals), *$T := I union L union B$* the set of all RDF Terms and for further use *$V$* the set of all variables. Let
  subject $bold("s") in bold("I") union bold("B")$,
  predicate $bold("p") in bold("I")$ and
  object $bold("o") in bold("T")$.

  Then, following @W3C_RDF_1.1_Reference, any three-tuple or triple in an RDF graph is of the form

  $
    (bold("s"), bold("p"), bold("o"))
  $
  #align(center)[or equivalently]
  $ 
    bold("s") xarrow(bold("p")) bold("o"),
  $
] <def:spo>

#definition[An *RDF graph* is a set of RDF triples. An RDF triple is said to be asserted in an RDF graph if it is an element of the RDF graph @W3C_RDF_1.2_Proposal.] <def:rdf_graph>

if subject *$s$* relates to object *$o$* in a way which the predicate *$p$* describes.

#example[
  Suppose a subject is given the name "Johann Wolfgang von Goethe", which relates to an object of the name "University of Leipzig", in the way, that the subject was educated at the object. Using the formalism from @def:spo, one might be inclined to produce something like:
  $
    bold("s") := "Johann Wolfgang von Goethe", \
    bold("p") := "educated at", \
    bold("o") := "University of Leipzig",
  $
  $
    "Johann Wolfgang von Goethe" xarrow("educated at") "University of Leipzig."
  $ <ex_spo_goethe>
]

=== Internationalised Resource Identifier <heading:iri>

Internationalised Resource Identifiers (IRIs) [#link("https://www.ietf.org/rfc/rfc3987.txt")[RFC3987]] are a superset of Uniform Resource Identifiers (URIs) [#link("https://www.ietf.org/rfc/rfc3986.txt")[RFC3986]], for example `http://database.factgrid.de/entity/Q409`. Their purpose is to *refer to a resource*. The resource an IRI points at is called *referent*. 

The main advantage of IRIs over URIs are their enhanced character set. However, the details are not directly relevant to this work, therefore I will simply refer to the quoted RFCs for further reading.

=== Literals <heading:literals>

The definitions in this section follow the *RDF v1.2* specifications @W3C_RDF_1.2_Proposal, which, at the time of writing, is a working draft. Again, the technical specifications are not directly relevant to the matters of this work, therefore I will abstract from the implementation details. 

#definition[
  A *literal* in an RDF graph can be used to express values such as strings, dates and numbers. It can have two to four elements:
  + a *lexical form*, which is a Unicode string,
  + a *data type IRI*, which defines the mapping from the lexical form to the literal value in the user representation. (also note the remark below this list)
  + an optional *language tag*, which allows to add express from which language the *lexical form* stems and
  + an optional *base direction tag*, which occurs in combination with the *language tag* to indicate the reading direction (either left-to-right or right-to-left).

  _Remarks: (1) The necessity of the language and base direction tag are indicated by two separate *special IRIs*. (2) The only difference to RDF v1.1 is, that is does not allow for a base direction tag._ 
] <def:literals>

#definition[
  The *literal value* of a *literal* in an RDF graph is defined in dependence of the fields available in the *literal*. The availability of a tuple entry is characterising for the *literal type*. The literal value is a tuple. #todo[mention, whether this is supported in the implementation]

  #figure(caption: [Mapping from literal to literal value],
  align(center, table(columns: 2, align: horizon,
    [Literal Type], [Literal Value],
    [language-tagged], [(lexical form, language tag)],
    [direction-tagged], [(lexical form, language tag, base direction tag)],
    [has IRI stated in the\ #link("https://www.w3.org/TR/rdf12-concepts/#dfn-recognized-datatype-iri")[list of recognised data type IRIs]], [the literal value interpreted\ as the indicated data type]
  )))
]

=== Blank nodes
RDF specifies *blank nodes*, which do not have an IRI nor a literal assigned to them. The specification @W3C_RDF_1.1_Reference and the current version of its successor @W3C_RDF_1.2_Proposal do not comment on the structure of a blank node: "Otherwise, the set of possible blank nodes is arbitrary." @W3C_RDF_1.1_Reference.
It only specifies, that *the set of blank nodes is disjunct from all literals and IRIs*. In most common RDF formats, a blank node can be locally referenced using a *local name* and a special "empty" IRI-prefix often denoted by an underscore character.

/*=== Modelling Information using Triples

Suppose, that the assertion from @ex_spo_goethe is part of the A-box of an RDF database. It can be deducted that:
#todo[such statements are called entailments]:
- there is something called "Johann Wolfgang von Goethe",
- using the assumption that a different symbol implies a different object, there is something different from Goethe, called "University of Leipzig",
- there is a directed relation called "educated" at and
- of course the assertion itself, meaning that the relation applies between these two objects.

A computer still does not understand what it means to be educated at some place or where Leipzig is, but it can interact with this information in a formally correct way. The human operator can construe meaning, an interpretation grounded in the real world, in to the assertion. 

However, for any structured querying to be possible, the databases ought to be filled according to certain conventions. Preferably such conventions that are interoperable with other data sources (see @heading:lod).*/

=== SPARQL Protocol and RDF Query Language <heading:sparql>

The acronym _SPARQL_ is recursive and stands for *S*\PARQL *P*\rotocol *A*\nd *R*\DF *Q*\uery *L*\anguage. It is considered to be a _graph based_ query language. This section follows its currently recommended specification v1.1 @W3C_SPARQL_Specification.

#blockquote[
  SPARQL can be used to express queries across diverse data sources, whether the data is stored natively as RDF or viewed as RDF via middleware. SPARQL contains capabilities for querying required and optional graph patterns along with their conjunctions and disjunctions. [...] The results of SPARQL queries can be results sets or RDF graphs. @W3C_SPARQL_Specification
]

The following section follows the _Formal Definition of the SPARQL query language_ @W3C_SPARQL_Formal_Definition. All relevant aspects of the formal definition are clarified in this work. Readers interested in further details are encouraged to consult the documentation directly.

#definition[
  A *Basic Graph Pattern (BGP)* is a *subset* of SPARQL triple patterns
  $(T union V) times (I union V) times (T union V)$.
]<def:bgp>

#definition[
  A *Graph Pattern* is one of: *Basic Graph Pattern*,
  _Group Graph Pattern_,
  _Value Constraints_,
  _Optional Graph Pattern_,
  _Union Graph Pattern_ and
  _RDF Dataset Graph Pattern_.
]<def:graph_pattern>

#definition[
  A *SPARQL query* is defined as a tuple $(G P, D S, S M, R)$ where:
  $G P$ is a graph pattern,
  $D S$ is an RDF Dataset (essentially a set of RDF graphs),
  $S M$ is a set of solution modifiers and
  $R$ is a result form. A *SPARQL-SELECT query* is a SPARQL query, where $R$ is a _projection statement_. Furthermore, a SELECT query has requires a _projection variables_, which will be returned as results and a _selection-clause_ (indicated by the keyword `WHERE`), which contains Basic Graph Patterns (see @def:bgp).
]<def:sparql_query>

#remark[
  This implies, that a SPARQL query can query for a triple, which has a literal as its subject. #todo[How does this make sense?]
]

Writing SPARQL queries is pretty straight-forward: The wanted structure
is expressed in terms of the query language, and the unknown parts are replaced by variables. Say the user wants to know which universities Goethe went to. The matching query would look like @example:goethe_query.
#figure(caption: "A SPARQL query to determine which educational institutions Goethe visited.",
  ```HTML
  PREFIX wd: <http://www.wikidata.org/entity/>
  PREFIX wdt: <http://www.wikidata.org/prop/direct/>
  SELECT ?1 WHERE {
      wd:Q5879 wdt:P69 ?1 .
      # Johann Wolfgang von Goethe -- [educated at] -> Variable
  }
  ```
) <example:goethe_query>

==== Results of a SPARQL query
The result can either be a set of possible value combinations
#todo[Finish section]

==== Expressing IRIs
An IRI in SPARQL is indicated by the delimiters `<` and `>` (in that order). 

==== Prefixes and bases <def:prefixes_and_bases>
SPARQL allows to define a *prefix*, which acts as an *abbreviation of an IRI*. The IRI `http://www.wikidata.org/entity/Q5879` can be abbreviated using the above defined prefix as `wd:Q5879`. The part after the colon is called *local name* and is essentially a string restricted to alphanumerical characters.
A *base* works similarly, only that it is prefixed to any IRI in the document. It is also prefixed to `PREFIX` statements, as you can see in @example:arbitrary_position_of_base_and_prefix.

#figure(caption: [The position of a statement in a SPARQL query\ does not have an effect on the result.],
  ```HTML
  PREFIX wd: </entity/>
  BASE <http://www.wikidata.org/>
  PREFIX wdt: <http://www.wikidata.org/prop/direct/>
  SELECT ?1 WHERE {
      wd:Q5879 wdt:P69 ?1 .
  }
  ```
) <example:arbitrary_position_of_base_and_prefix>

=== RDF Data Model in Wikibase
*Wikibase* is one of the most widely used softwares for community knowledge bases, with the most prominent instance, *Wikidata*#footnote[http://wikidata.org --- an initiative for a free community knowledge base], storing \~115 million data items. Wikibase instances allow for a mapping from their internal storage to an expression in RDF syntax @wikibase_rdf_mapping_article. This invertible mapping permits the use of _RDF terminology to refer to structures within Wikibase_. Also relevant to this work are the prefix conventions of Wikibase, which will come to play in @heading:qualifiers and @heading:implementation. This specific data model is interesting, because of its wide use, it influences other initiatives due to its sheer size. For example, DBpedia will make use of Wikidata resources @Lehmann2015DBpediaA.

In Wikibase, a *thing* is referred to as an *item* and assigned a unique *Q-Number* within a Wikibase instance. Any *predicate* is called *property* and assigned a unique *P-Number*. Both items and properties are *entities* and have their own IRI.

As can be seen in @example:prefixes_in_wikidata, there are many prefixes apparently for the same things, namely *items* and *properties*. However, their use 
in Wikibase depends on the context. @fig:rdf_mapping shows how they come into play in the Wikibase data model. It is important to mention, that once an item 
or property is added to Wikibase, it is referencable using all of the prefixes of the data model. Using the concrete example of Wikidata, an item can be directly addressed using the prefix `wd` and a property directly accessed using `wdt`.

#todo[
  Ich sollte das Beispiel mit den Prefixes erläutern und auch warum ich es zeige. Das wird noch nicht klar.
  Ich erkläre kurz wie für die Implementation wd wdt pq relevant sind.
]


/*```turtle
 wd:P22 a wikibase:Property ;
     rdfs:label "Item property"@en ;
     wikibase:propertyType wikibase:WikibaseItem ;
     wikibase:directClaim wdt:P22 ;
     wikibase:claim p:P22 ;
     wikibase:statementProperty ps:P22 ;
     wikibase:statementValue psv:P22 ;
     wikibase:qualifier pq:P22 ;
     wikibase:qualifierValue pqv:P22 ;
     wikibase:reference pr:P22 ;
     wikibase:referenceValue prv:P22 ;
     wikibase:novalue wdno:P22 .
```*/

#figure(caption: [An excerpt of customary IRI prefixes defined by Wikidata.],
```HTML
PREFIX p: <http://www.wikidata.org/prop/>
PREFIX pq: <http://www.wikidata.org/prop/qualifier/>
PREFIX pqv: <http://www.wikidata.org/prop/qualifier/value/>
PREFIX pr: <http://www.wikidata.org/prop/reference/>
PREFIX prv: <http://www.wikidata.org/prop/reference/value/>
PREFIX ps: <http://www.wikidata.org/prop/statement/>
PREFIX psv: <http://www.wikidata.org/prop/statement/value/>
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wds: <http://www.wikidata.org/entity/statement/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>
PREFIX wdv: <http://www.wikidata.org/value/>
PREFIX wikibase: <http://wikiba.se/ontology#>
```
) <example:prefixes_in_wikidata>


Often in Wikibase, the same local name is used in combination with different IRI prefixes to address different aspects of the same assertion. For further use in this work, I will define sets of prefixes and mappings to prepend a prefix to a local name.

#definition[Let $Sigma$ be a valid alphabet for local names and $Sigma^*$ its Kleene closure. Let
  $f_bold(p), f_bold(q), f_bold(s) in I$ be _distinct_ IRI prefixes for so called *p*\roperties, *q*\ualifying properties and property *s*\tatements. Any IRI $i in I$ with a prefix $f_x in I$ can be written as $i = f_x u$ and $u in Sigma^*$#footnote[Technically, a valid prefix could be written e.g. without a trailing slash. For the purposes of this work, I consider the basic concatenation to work like the concatenation algorithmm for URIs specified in #link("https://www.ietf.org/rfc/rfc3986.txt")[RFC3986], if necessary.].
] <def:prefix_formally>


#figure(caption: [Informal overview of Wikibase conventions for\ mapping information about an Item to the RDF standard @wikibase_rdf_mapping_graphic.],
  image("rdf_mapping.svg", width: 87%)
) <fig:rdf_mapping>

=== Qualifiers <heading:qualifiers>
Most real-world relationships might present to be more complex than something one would want to model in a single triple. For example, one may want to express that "Goethe" was educated at the "University of Leipzig" from 3 October 1765 to 28 August 1768. One possibility is to let relationships have more than two operands, i.e. increase the arity by one for each additional parameter. "Educated at" would then be called "educated at (#sym.dot) from (#sym.dot) to (#sym.dot)". Another way using the already existing triple syntax is to create an implicit object, that assists in modelling the relationship. We use it to describe a new concept; a human might be inclined to give it a name, e.g. "educated at for a certain time". 

#figure(
  caption: [Presentation of an implicitly defined relationship in the software Wikibase.],
  image("screenshot_wikidata.png", width: 220pt)
)<fig:qualifier_screenshot>
The following triples exemplify such an implicit relationship, called a *qualified statement*:
$
  "Goethe" &longArrow("educated at") && "Uni Leipzig", \
  "Goethe" &longArrow("educated at") && "Implicit1", \
  "Implicit1" &longArrow("educated at") && "Uni Leipzig", \
  "Implicit1" &longArrow("started at") && 3.10.1765, #<ex_qualifier_1> \
  "Implicit1" &longArrow("ended at") && 28.08.1768.  #<ex_qualifier_2>
$ <ex:assertions_goethe_education>

Having specified the qualified statement "educated at for a certain time", one is free to add a few extra statements about what he studied and whether he graduated:

$
  "Implicit1" &longArrow("field of study") && "Law", \

  "Implicit1" &longArrow("graduated") && "True".
$ <ex:assertions_goethe_education_revised>

#remark[Would the above example be formalised in RDF syntax, _Goethe_ and _Uni Leipzig_ would be IRIs, _Implicit1_ a blank node, and the dates and booleans literals.]

#figure(image("Qualifier_ohne.svg"), caption: [Graphical visualisation of a qualifier using natural language.]) <fig:vqg_no_qualifier>

The term and concept "qualifier" is *not* used or specified in the RDF reference @W3C_RDF_1.1_Reference @W3C_RDF_1.2_Proposal. The definition below follows the Wikibase conventions @wikibooks_sparql_qualifiers @wikidata_sparql_qualifiers, where the property and value of the *qualified edge\/assertion* are displayed hierarchically above the qualifiers, as seen in @fig:qualifier_screenshot. 
In this work, the term *qualifier* can be used in *three ways*: The *concept* of a qualifier, is that a relationship between items can be further specified using them. The now following definition refers to qualifiers, which can be *asserted in an RDF graph*. The third meaning is a qualifier in a *qualifiable Visual Query Graph*, which will be defined later on. 

In order to model and query a qualifier in an RDF database, distinct prefixes for statements and qualifiers are necessary. In SPARQL queries a variable is used to match a blank node, such as "Implicit1". Now, the Wikibase data model allows for many more constructs involving a blank node connected to an item. Furthermore, to correctly display the qualified edge and the qualifying edges, the property IRI prefixes ought to be discernable. In Wikibase, there is always a direct edge from the subject to the object using the `wdt:` prefix. First, this is necessary, should the database's user not want to query for a qualifier, but just for the "regular" assertion. Then, there are the constructing parts of the qualifier: the statement edge from the subject to the blank node using `p:`, the property statement edge from the blank node to the "main" assertion using `ps:` -- e.g. "educated at" in @ex:assertions_goethe_education -- and lastly the qualifier edges, using the `pq:` prefix. Using these prefixes, the data model allows to point at one and the same item, but from very different contexts. To model qualifiers, they ought to be formally defined.

/*#todo[move this somewhere where it makes sense]
The semantically similar assertions $(s,p,o)$ and $(b, p_s, o)$ are not erroneous, but an implementation detail of Wikibase to be able to differentiate the qualifiers from the qualified edge.
*/

#definition[
  Let $G$ be an RDF graph, $s in I$ be a specific subject,#sym.space.med
  $Q:= { f_bold(q) u | u in Sigma^*}, Q subset I$ a set of qualifier IRIs with $q_i in Q$,#sym.space.med
  $P:= { f_bold(p) u | u in Sigma^*}, P subset I$ a set of predicate IRIs, with $p in P$  
  and the limitation the first qualifier  $u in Sigma^*$, $q_1 = f_q u <=> p = f_p u$. Additionally, let $p_s$ and $p$ refer the same local name (or Wikibase property) using different prefixes
  $p_bold(s) := f_bold(s) u <=> p := f_bold(p) u$. Lastly, let $o in L union I, o_j in O subset.eq L union I$ an arbitrary set of objects and
  $b in B$ a blank node. Then, a *qualified statement* in $G$ is defined as a set containing the triples
  $
      {(s, bold(p), b), (b,p_s,o)} union {(b, q_i, o_i) | i in NN}.
  $
  Statements such as $(b, q_i, o_i)$ are called *qualifiers* in $G$ and the triple $(s, f_t u, o)$ with $u in Sigma^*$ would be called *qualified edge* in the RDF graph $G$.
] <def:qualifiers>

#figure(
  caption: [A visualisation of a qualified statement with two qualifiers using the terms introduced in @def:qualifiers. The `wdt:` description is used in analogy to the Wikibase RDF data model figure. It is to be interpreted as an IRI with the instance-specific prefix `wdt` and a valid arbitrary local name.],
  image("Qualifier_abstract.svg")
)
#todo[Make sure, that this figure is on the same page as the definition above.]

// This method of describing information allows us to implicitly define new concepts. Any program dealing with qualifiers merely handles the explicit assertions for an anonymous concept. But, this anonymity poses a challenge to a human interpreter; implicit concepts usually remain unnamed (#todo[below (how does it work)]).


== Visual Query Graph
#definition[
  Following @Vargas2019_RDF_Explorer, a *visual query graph* (VQG) is defined as a directed, edge- and vertex-labelled graph $G=(N,E)$, with vertices/nodes $N$ and edges $E$. The nodes of $G$ are a finite set of IRIs, literals or variables: $N subset bold("I") union bold("L") union bold("V")$.
  The edges of the VQG are a finite set of triples, where each triple indicates a directed edge between two nodes with a label taken from the set of IRIs or variables: $E subset N times (bold("I") union bold("V")) times N$.
] <def:vqg>

A qualifier, as defined in @heading:qualifiers, would now be constructed as shown in @fig:vqg_no_qualifier.


#definition[
  Following @def:vqg, a *qualifiable visual query graph* (qVQG) is a directed, edge- and node-labelled graph $G_q=(N,E,E_q)$ with $N, E$ as defined above, $Q subset I$ the set of designated qualifier IRIs (see @def:qualifiers) and $E_q subset E times Q times N$.
] <def:qvqg>

#definition[
  A *qualifier* in the *qualifiable visual query graph* $G_q=(N,E,E_q)$ with $N, E, Q$ is a special directed, labelled edge $bold(e_q) in E_q$ as defined above and $bold(e_q) in E_q subset E times Q times N$. Let $e_q = (e, q, n)$ be a qualifier in $G_q$, then $e in E$ is called *qualified edge*, $q in Q$ is called *qualifying edge* and $n in N$ is called *qualifying value*.
] <def:qvqg-qualifier>

#todo[
  This is probably still unclear.
]

#let vql_ops = (
   [User Interaction],
    [Adding a variable node],
    [Adding a literal node],
    [Adding a directed edge],
    [*Adding a qualifier*]
)

Following @Vargas2019_RDF_Explorer, the qVQG is _constructed_ using the _qualifiable visual query language (qVQL)_, consisting of #{vql_ops.len()/2-1} algebraic operators, which will correspond to atomic user interactions of the VQG: adding a variable node, adding a literal node and adding a directed edge. In addition, I propose the actions of adding and removing an edge qualifier.

#figure(
  caption: "Operations in the VQL",
  table(columns: 1,
  ..vql_ops
  )
)

Using this new *qVQG* and qVQL, we can now create an intuitive visualisation (see @fig:vqg_with_qualifier) as motivated by @Simons_Blog_Entry_Graphic_query. Now, it needs to be shown, that the qVQG can be losslessly translated to a VQG and in turn to a SPARQL-SELECT query.

#figure(image("Qualifier_mit.svg"), caption: [Qualifiers in the qVQG]) <fig:vqg_with_qualifier>

#todo[How could a blank node in a qVQG look like? #sym.arrow they are currently just ignored by the Rust code.
- To represent a blank node I simply use a variable. The query will match the blank node and the variable is left out in the projection statement.
]

== Mapping Visual Query Graphs to SPARQL queries <heading:mapping_theory>

#todo[Is the mapping invertible? Beweis ggf. durch Gegenbeispiel.]

The goal of this section is to define a mapping from VQGs to SPARQL-SELECT queries. Much of the SPARQL query language's expressability is covered by BGPs. Further components, such as value constraints with the keyword `FILTER` could possibly also be visualised in the VQG, but are currently not defined. First, the goal is to show, that a VQG and qVQG can be converted to BGPs and the second step is to show how a SPARQL-SELECT query can be constructed from this.

#lemma[
  Let $E':= (I union L union V) times (I union V) times (I union L union V)$ be the set of all possible edges in a VQG. Let Y be the set of all possible triples $Y:=(T union V) times (I union V) times (T union V)$ (a finite subset of which is a BGP). A BGP is now constructed using the mapping
  $
    f: E' &-> Y, \
    (s, p, o) &arrow.bar (s, p, o).
  $
]

#proof[
  For the mapping to be accurate, $E$ needs to be a subset or equal to $X$. Since both VQGs and BGPs allow variables at any position in the triple, it now only needs to be shown, that for $T: = I union L union B$ it holds true that $I union L subset.eq T$, which is trivially true from the definition of $T$.
   #todo[Lektorat notwendig.]
]

In order to convert a SPARQL SELECT-query to a VQG, this translation needs to be invertible. Since a valid query can have blank node specifiers for subjects and objects, but the VQG is defined without blank nodes, some replacement needs to be found. The SPARQL specification#footnote[in section 4.1.4 Syntax for Blank Nodes] however concludes, that a blank node can be written as a variable in a query @W3C_SPARQL_Specification. Therefore, in order to create a VQG from a BGP, the mapping is inverted and for any blank node a variable is inserted. If a blank node occurs multiple times in a query, the same variable will be used for all occurences.

#todo[Sollte ich das noch einmal lemmatisieren und beweisen?]

Using the above lemma, a VQG can already construct a qualifier. The blank node can be replaced by a variable and the only other obligation is to use the correct prefixes.

#lemma[
  Let again $E':= (I union L union V) times (I union V) times (I union L union V)$ be the set of all possible edges in a VQG. Let $E'_q := E times Q times N$ be the set of all possible qualifier edges with elements of the form $(e_q, q, n)$. Let $E$ be the set of valid edges in a VQG with elements of the form $(s_e, p_e, o_e)$. Let $v in V$ be a unique variable for each triple in $E_q$ and $w in Sigma^*$. Qualifiers can now be converted to valid VQG triples using the mapping
  $
    g: E_q &-> E', \
    ((s_e, (f_t p_e), o_e), q, n) & arrow.bar {(s_e, f_p p_e, v), (v, f_s p_e, o_e), (b, q, n)}
  $
]
#todo[Ist es in Ordnung das so aufzuschreiben? Vielleicht "hash"funktion für Variablenbezeichner abhängig von qualified edge.]

#proof[
  Poof! #emoji.explosion
  #todo[
    Mehrere unterschiedliche Variablen zu verwenden ist in Ordnung, weil das bei einer Abfrage keine Rolle spielt. Die unterschiedlichen Variablen würden auf die gleichen Strukturen im RDF graph matchen. Es wäre allerdings schön, dass man die Variablen wiederverwenden kann, wenn es sich auf die gleiche qualified edge bezieht. Ich könnte eine "Hash"funktion definieren, die die qualified edge auf eine Variablenbezeichnung abbildet.
  ]
]

#todo[Ist die Abbildung invertierbar?]

= Results <heading:implementation>

#todo[
Should contain the following aspects:
- start with a theoretical approach
- describe the developed system/algorithm/method from a high-level point of view
- go ahead in presenting your developments in more detail
]

#todo[
  My work also has the advantage, that all conventions are regulated in a configuration file specifically for data sources. A user (in the future) can add
  new conventions at a central place and will know, which effects changes have. 
]

== Approach and Considerations

The goal of this work is to create two mostly separate programs:
+ the _visual query building interface_ (forthon called *frontend*) and
+ the _translator between VGQ and SPARQL_ (forthon called *backend*).

The most important aspects for the choice of software and UX design were usability and maintability. The aim is to lay the basis for a software, which can be applied in day-to-day use as an "almost-no-code" query builder. The development of Query by Graph will be continued in the project _HisQu_ by the #link("https://www.mephisto.uni-jena.de/")[MEPHisto group] funded by #link("https://4memory.de")[NFDI4Memory]. Therefore, this work's focus lay on building an extensible, future-proof platform, rather than implementing every thought-of feature.

As motivated in the introduction in order to answer a question, the questioner needs to know enough to ask the question. Query by Graph _does not assist this step_. Secondly, the questioner needs to formalise the question into a BGP. This involves finding the appropriate items and properties in the Wikibase instance. Query by Graph aids this step by offering a direct access to the fuzzy search API. I should add, that the search _does not avert the studying of conventions of a Wikibase_. 

#todo[probably remove the following paragraph]
The step of formalising a natural-language question into a SPARQL query seems simple, however the first challenge arises in finding the correct entities for the query --- let alone the formalisation of the question itself. For example, the question `Find all Nobel prize winners with a student who won the same Nobel prize` (taken from @Vargas2019_RDF_Explorer) is not as simple to model as it would seem at first glance. In Wikidata, three properties are suggested for the search term "student": `wdt:P802 "student"`, `wdt:P1066 "student of"` and `wdt:P69 "educated at"`. In some cases the specific property does not matter. Wikibase instances have the disadvantage, that because they commonly lack an extensive ontology, data consistency varies. The user should be offered an abstraction layer, e.g. to assign a set of properties to an edge in the VQG or to generate the query using a _partial_ ontology. It is cumbersome to the user to remember every conventions, especially, when they could be automatically enforced using a partially defined ontology.

#todo[put this idea in future work as well]

#figure(
  caption: [SPARQL query: Find all Nobel prize winners with a student who won the same Nobel prize. @Vargas2019_RDF_Explorer],
```HTML
PREFIX wd: <http://www.wikidata.org/entity/>
PREFIX wdt: <http://www.wikidata.org/prop/direct/>
SELECT ?prize ?student ?winner WHERE {
     ?winner wdt:P166 ?prize .
    # Variable -- [award received] -> Variable     ?student wdt:P802 ?winner .
    # Variable -- [student] -> Variable
     ?student wdt:P166 ?prize .
    # Variable -- [award received] -> Variable
     ?prize wdt:P31 wd:Q7191 .
    # Variable -- [instance of] -> Nobel Prize
}
```
)

#remark[Though the query copied from @Vargas2019_RDF_Explorer seems to be correct, it yields an empty result. There are two items which are `instance of` `Nobel prize`, however, neither are a Nobel prize.]

#todo[Wie formuliere ich hier freundlich, dass obwohl ein Werkzeug verwendet wurde das die möglichen Ergebnisse einer Abfrage im Voraus anzeigt, die produzierte Abfrage trotzdem keine Ergebnisse liefert, der Sinn und die Nutzbarkeit des Tools also fragwürdig scheint.]


== Architecture
Since SPARQL is mostly used in the context of a web browser, the choice for a web app seemed obvious. The backend was designed to be explainable and traceable. For this, there are several good choices, especially functional programming language, but since Rust#footnote[http://www.rust-lang.org] can be compiled to Web Assembly#footnote[http://webassembly.org] and therefore executed natively in a browser, the choice fell well in its favour over a server-client architecture. This combination of architectures proves to be extendable, quick and still formally precise.

#todo[Mention, that I am limited to two prefixes, wdt and wd. Also mention, that there is a configuration file, which contains all Wikibase data sources. ]

The *frontend* was written using the libraries Vite, Vue3, ReteJS and TailwindCSS (all licensed under MIT license). Its purpose is to allow the user to
+ build a VQG, and edit it from the SPARQL code editor,
+ searching for items and properties in arbitrary Wikibase instances,
+ display meta-information on items and properties,
+ configure Wikibase data sources and
+ handle all data source specific tasks (such as enriching entities with information from a Wikibase instance).

The *Wikibase data sources* are configured by the user and stored in the browser's local storage. Following the conventions of Wikibase, the choice was made to only allow one prefix for items and one for properties. The program assumes, that the item prefixes point directly to the item, e.g. `wd` for Wikidata, and the property prefixes to the property value, e.g. `wdt` (for reference on the data model see @fig:rdf_mapping). This assumption is based on the premise that users writing queries involving more than this level of abstraction, typically have a deeper understanding of the underlying mechanics and are likely capable of composing an adequate SPARQL query.

The *backend's* purpose is to handle the algebraic parts of the mapping between SPARQL queries and VQGs. 

To ensure compatibility between the backend and frontend, both use the same type definitions. They are exchanged using JSON serialisation and deserialisation.
An entity is considered to have the properties shown in the listing below. #todo[change the reference, if the bug is fixed or I rendered it externally.] 

#figure(caption: [Key Data Types for the translation between VQG and SPARQL.],
```pintora
classDiagram
  class PREFIX {
    string iri
    string abbreviation
  }
  class WIKIBASEDATASOURCE {
    string name
    PREFIX propertyPrefix
    PREFIX itemPrefix
    string[] preferredLanguages
  }
  class ITEM {}
  class PROPERTY {}
  class ENTITY {
    string id
    string label
    PREFIX prefix
    WIKIBASEDATASOURCE dataSource
  }
  ENTITY <|-- ITEM
  ENTITY <|-- PROPERTY
  
  class CONNECTION {
    PROPERTY property
    ITEM source
    ITEM target
  }
  PREFIX "1" o-- "*" ENTITY
  PREFIX "2" o-- "*" WIKIBASEDATASOURCE

  ENTITY "*" --o "1" WIKIBASEDATASOURCE
  
  CONNECTION "2" o-- "*" ITEM
  CONNECTION "1" o-- "*" PROPERTY
```
)

#figure(caption: [Restructured data types for qVQGs.],
```pintora
classDiagram
  class WIKIBASEDATASOURCE {
    string name
    PREFIX propertyPrefix
    PREFIX itemPrefix
    PREFIX qualifierPrefix
  }
  class ITEM {}
  class PROPERTY {}
  class QUALIFIER {
    PROPERTY property
    ITEM target
  }
  class ENTITY {
    string id
    string label
    PREFIX prefix
    WIKIBASEDATASOURCE dataSource
    QUALIFIER[] qualifiers?
  }
  ENTITY "*" --o "1" WIKIBASEDATASOURCE
  ENTITY <|-- ITEM
  ENTITY <|-- PROPERTY
  PROPERTY "1" *-- "*" QUALIFIER
  ITEM "1" *-- "*" QUALIFIER
```
)

#todo[
- mention which tools I used (spargebra)
- and how the algorithm comes to its results

The pipeline from VQG to SPARQL query and vice versa needs to be made clear:
- especially comment on optimisations, like when something is semantically equal i do not redraw the VQG
- when is something semantically equal?
]


#figure(
  caption: [An overview of all features currently implemented.\ "#sym.checkmark" means implemented and tested, "(#sym.checkmark)" means implemented but not bug-free and "#sym.crossmark" means not implemented. A full feature list can be found in the technical documentation of the repository.],
  table(columns: 2,
    [Feature], [Status],
    [Drawing a VQG with variables and literals], [#sym.checkmark],
    [Searching for entities on multiple Wikibase instances], [#sym.checkmark],
    [Creating SPARQL-SELECT queries from a VQG], [#sym.checkmark],
    [Code editor for SPARQL queries], [#sym.checkmark],
    [Applying changes in the code editor to the VQG], [(#sym.checkmark)],
    [Enriching unseen entities with metadata from the Wikibase API], [(#sym.checkmark)],
    [Literals with standard RDF data types (string, int, date, ...)], [(#sym.checkmark)],
    [Use multiple Wikibase instances as data sources], [#sym.checkmark],
    [Meta-Info Panel], [#sym.checkmark],
    [Rendering qualifiers with the proposed visualisation], [#sym.crossmark]
  )
)

== VQG-SPARQL Mapping Algorithm

The implementation of the mapping between VQGs and BGPs uses two different algorithms for each direction of the mapping.

=== VQG to SPARQL
The mapping is done according to the proofs in @heading:mapping_theory. The VQG is exported in the form of an edge list from the frontend to the backend. The elements of the edge list are triples, corresponding to BGPs, and each entry of the triple is a literal, variable or IRI --- or to use Wikibase terminology, an entity. The BGPs in turn are mapped to a SPARQL-SELECT query with all variables from the VQG added to the projection. #todo[Check if this is still the case when I am finished with the qualifier feature, or whether I leave out the blank-node-placeholder variables.]



#todo[define what a SPARQL select query is]

Novel to current work @Vargas2019_RDF_Explorer @Vargas2020_UI_for_Exploring_KGs, _the generated query is displayed instantaneously_ below the visual query builder, thanks to the speed of the backend. 

=== SPARQL to VQG
The backend makes use of a SPARQL parser package called `spargebra`. Currently, only the mapping from SPARQL-Select-queries with BGPs is defined without loss in the implementation. Any language feature which is not implemented will be ignored, e.g. the SPARQL keywords like `FILTER` are ignored. The used parser package, however, has definitions for most#footnote[Here, I must say I did not notice an important language feature which is not implemented, however, there is no statement by the makers which asserts this statement.] of the SPARQL language features. These features can be very easily added in future versions, thanks to the program's modular design. 

Novel to current work:
+ Qualifiers are visualised more intuitively (see Simons Blog @Simons_Blog_Entry_Graphic_query)
+ Multiple data sources and clear prefixes #todo[Check, whether this is actually new]
+ ... more?

#todo[
  Explain which shortcomings in addition to the theoretical ones this makes. (If there are any)
]

#todo[
  Mention the reason for use of wdt prefix (https://www.mediawiki.org/wiki/Wikibase/Indexing/RDF_Dump_Format#Truthy_statements)
]


#todo[
  Explore the expression capabilities of my tool. Can it write an arbitrary SPARQL query?
]

#todo[
  Does Wikibase really only use one property and item prefix when it returns from this query?
  This has the very big limitation, that if a user uses a different prefix, that it does not work.
  Maybe I should comment on this from a user perspective, as in: "a standard user will not write a query so complex, that it cannot do this".
  ```javascript
  export interface WikibaseDataSource {
    name: string;
    url: string,
    preferredLanguages: string[],
    propertyPrefix: {
        iri: string,
        abbreviation: string
    },
    itemPrefix: {
        iri: string,
        abbreviation: string
    },
    queryService: string,
}
  ```
]

#todo[
  Write the missing capabilities:
  - I cannot write SPARQL local names
  - no Filters
  - ...
]

#todo[
  How could I implement something like the same-time highlighting of code and node in the graph?
  - instead of deleting the node, I simply look for equivalents and change the class properties
  - i calculate the steps of algebraic operations necessary to build the graph
]


#todo[
  For the convertConnectionsToPrefixedRepresentation to work,
  the item and property prefixes must be prefix-free (one may not be prefix of the other).
]

#todo[
- whatever you have done, you must comment it, compare it to other systems, evaluate it
- usually, adequate graphs help to show the benefits of your approach
- caution: each result/graph must be discussed! what’s the reason for this peak or why have you observed this effect
]

== Practical Application
- Patrick Stahl developed for Clemens Beck
- Changes / contributions by patrick are clearly marked in Version Control

== User Feedback
// 100% of female users reported that the user interface looked very nice.

#todo[
  Why does it make sense, that a user can edit a SPARQL query?
]

= Further Work <heading:further_work>

+ Creating/Manipulating RDF assertions (INSERT and UPDATE statements)

+ Many language features of SPARQL:
  - FILTER
  - JOIN
  - Aggregate
  - SUBSTR
  - ...
  - "\[AUTO\_LANGUAGE\],de"

+ Implementing the OWL integration within Query by Graph

+ If an entity in the SPARQL query is selected, also highlight in the retejs editor

+ If the query is changed, try to not move the nodes, but reuse their position.
  - this would involve rewriting the importConnections

+ Formulating queries from natural language using Large Language Models

```XML
xsd:integer
xsd:decimal
xsd:float
xsd:double
xsd:string
xsd:boolean
xsd:dateTime
```

= Declaration of Academic Integrity

#todo[Last edited: January 2024, check for a newer version when I submit]

1. I hereby confirm that this work — or in case of group work, the contribution for which I am responsible and which I have clearly identified as such — is my own work and that I have not used any sources or resources other than those referenced.

   I take responsibility for the quality of this text and its content and have ensured that all information and arguments provided are substantiated with or supported by appropriate academic sources. I have clearly identified and fully referenced any material such as text passages, thoughts, concepts or graphics that I have directly or indirectly copied from the work of others or my own previous work. Except where stated otherwise by reference or acknowledgement, the work presented is my own in terms of copyright. 
   
2. I understand that this declaration also applies to generative AI tools which cannot be cited (hereinafter referred to as "generative AI").

  I understand that the use of generative AI is not permitted unless the examiner has explicitly authorised its use (Declaration of Permitted Resources). Where the use of generative AI was permitted, I confirm that I have only used it as a resource and that this work is largely my own original work. I take full responsibility for any AI-generated content I included in my work. 
   
  Where the use of generative AI was permitted to compose this work, I have acknowledged its use in a separate appendix. This appendix includes information about which AI tool was used or a detailed description of how it was used in accordance with the requirements specified in the examiner#sym.quote.single\s Declaration of Permitted Resources. I have read and understood the requirements contained therein and any use of generative AI in this work has been acknowledged accordingly (e.g. type, purpose and scope as well as specific instructions on how to acknowledge its use). 

#todo[Check whether #sym.quote.single is the right thing to use here.]

3. I also confirm that this work has not been previously submitted in an identical or similar form to any other examination authority in Germany or abroad, and that it has not been previously published in German or any other language. 

4. I am aware that any failure to observe the aforementioned points may lead to the imposition of penalties in accordance with the relevant examination regulations. In particular, this may include that my work will be classified as deception and marked as failed. Repeated or severe attempts to deceive may also lead to a temporary or permanent exclusion from further assessments in my degree programme. 

#v(40pt)
#grid(columns: (1fr, 1fr), row-gutter: 1em,
  line(length: 150pt, stroke: (dash: "dashed")),
  line(length: 200pt, stroke: (dash: "dashed")),
  "Place and date",
  "Signature"
)
