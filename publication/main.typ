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

#set text(lang: "en", region: "GB")
#show: great-theorems-init

#let spct = sym.space.punct
#let assessor = [Prof.#spct\Dr. Clemens Beckstein\ M.#spct\Sc. Johannes Mitschunas]
#let degree = [Bachelor of Science (B.#spct\Sc.)]

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
    #todo[Write a heartwarming preface.]
  ],
  
  appendix: [
    #set heading(outlined: false)
    #todo[This chapter should contain all code listings, figures, tables and so on.]
    == Use of Generative AI
    This bachelor thesis was written in assistance of the OpenAI large language models GPT-4o and GPT-o1 preview. The large language models were used at the very start to get an overview over the domain, to ease literature research and to point out stylistic, orthographical and grammatical mistakes to the writer. The models were _not_ used to generate passages of this work. 
  ],
  
  abbreviations: (
    ("W3C", "World Wide Web Consortium (registered trademark)"),
    ("RDF", "Resource Description Framework"),
    ("RDFS", "Resource Description Framework Schema (Ontology within RDF)"),
    ("SPARQL", "SPARQL Protocol And RDF Query Language (recursive acronym)"),
    ("IRI", [Internationalised Resource Identifier (see @heading:iri)]),
    ("OWL", "Web Ontology Language"),
    ("VQG", "Visual Query Graph (user-built query graph)"),
    ("API", "Application Programming Interface"),
  ),

  external-link-circle: true, // TURN THIS OFF IF YOU GENERATE THE PRINT VARIANT
  
  figure-index: (enabled: true),
  table-index: (enabled: true),
  listing-index: (enabled: true),
  bibliography: bibliography(title: "Bibliography", style: "institute-of-electrical-and-electronics-engineers", "bib.yaml")
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

== Problem <problem_heading>
Much of the mankind's knowledge is stored in the format of natural language, which can not be accessed without following these steps: 1. rough research on a topic, 2. formulate a question using this map, 3. finding relevant literature to the question, 4. reading the literature, 5. extracting the relevant facts and, 6. reading more literature because the question is more complex than you thought 7. inferring an answer from the retrieved facts. This process can prove to be tedious and many of these steps have been eased for us -- may it be in the form of a librarian or a search engine.
 
The currently most used search engine, Google, uses of course Network Analysis but also Natural Language Processing (NLP) to identify the most relevant results to a topic. And just in recent years Large Language Models (LLMs) have shown interesting capabilities in compressing loads of knowledge using statistical analysis. An LLM is capable of giving an outline of any given topic or question, similar to a librarian, however any response is endangered by confabulation and ought to be verified. So, engineers successfully taught the computer to handle natural language for specific use cases somewhat reliably. But we might just go the last mile and ...

... let humans formalise knowledge in a computer-processible format. Using a formal ontology, any given relationship can be theorised #todo[Check whether I can make this statement]. This presents a two-fold advantage: Any statement is expressed in clearly interpretable terms and is viewed independently of any natural language constructs. The difficulty with formal ontologies, however, is anticipating all (or at least most) things and relations that need to be represented in advance. Therefore, ontologies require careful deliberation and their genesis usually goes by the saying: "Many cooks spoil the broth". Collaboration in ontology development is a real challenge, but a necessity.

So, how could this process avoided (or even supported), whilst not giving up the advantages of computer-processability? Originally conceptualised by Tim Berners-Lee, the W3C#sym.trademark.registered standardised the Resource Description Framework (RDF). While an ontology consist of a theory (T-Box) and assertions (A-Box, statements which are in compliance with the theory) a RDF knowledge base can consist purely of an A-Box. The T-Box is quietly implicit. Using an RDF schema, a taxonomy can be added (at any time), usually using an "instance-of" assertion, but consistency is no inherent obligation of an RDF database#footnote[although it is obviously good practice to be consistent with the RDF schema].

This "formalise as you go"-approach allows for maximal flexibility of the data model and proves advantageous, e.g. in the digital humanities. Recently, historians, among others, started to use centralised knowledge bases, allowing for collaboration on research questions and finding connections between the results from different researchers. A grand initiative called FactGrid#footnote[http://factgrid.de] hosts a free-to-use Wikibase instance tailored for the digital humanities, in the hope of creating synergy effects for future research.

This directly leads to the relevance of this work: Wikibase is a popular software for community knowledge bases and is RDF compatible. Such RDF databases#footnote[Technically, Wikibase uses a different internal representation and only maps to the RDF standard. @fig:rdf_mapping gives an overlook over the mapping.], however, can only be potently queried using a query language called SPARQL. Most researchers in the humanities will not find the time to study such arbitrary technicalities in-depth. Heavily inspired by Olaf Simons' article on the allure of a visual query interface, I reviewed several visual query helpers @Vargas2019_RDF_Explorer @KnowledgeGraphExplorationForLaypeople @Sparnatural and found them to have room for improvement in routine use and expressability. The aim of this work is to lay the groundwork for a visual query builder, which enables a previously unintroduced user to create complex SPARQL queries on Wikibase instances in daily use.

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

== Proposed Solution
This thesis aims to explore methods and concrete implementation, which guides the user through the process of finding an answer to a given question in an RDF database. This includes:

- enabling a layman to create complex SPARQL-SELECT-queries using a visual interface and

- allow changes to the SPARQL-SELECT-query, which will in turn change the graph in the visual interface.

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

== Related Work

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

= Fundamentals <heading:fundamentals>

== Semantic Technologies
#todo[

Questions, which I would like to be answered in this chapter:
- How can information about the real world be represented in a computer?
- What are RDF databases in comparison to other semantic technologies?
- What is the advantage of using a strict formal ontology in comparison to an RDF database?
]
@Dengel2012_Semantic_Technologies

// (There are Springer conferences on semantic web technologies: https://suche.thulb.uni-jena.de/Record/1041330375?sid=49057082)

#todo[
  Hier wir noch nicht deutlich, was der eigentliche Grundgedanke hinter semantischen Technologien eigentlich ist. Diese Sektion sollte ich gründlich überarbeiten, da Prof. B. sie genau lesen wird.
]

Computers generally lack information about the environment humans live in. For example, unless formalised, a computer is unaware of the fact, that an arbitrary arrangement of numerals separated by lines, such as `8/7/2000`, is supposed to represent a date within a calendar based on the birth of a religious figure. How would a human even know of this convention, if it were not taught to him? And even with this knowledge, one can easily stumble upon a false friend: Here, I picture a European fellow confronted with an American booking confirmation. The American interprets the above date as August 7th in the year 2000. In the worst case, the European confidently interprets it as July 8th and would probably be wrong. Explicating the date format would have prevented this disaster.

The original idea by Tim Berners-Lee was to annotate web pages using a well-defined common vocabulary, so that any computer can, without human assistance, extract the relevant contents of a website. For example, a doctors office might post opening times on their website. Using a well-defined and public vocabulary, the website describes a table as "opening times" and the strings of weekdays and times as entries of the opening times. #todo[insert example code from the book on Semantic Technologies] @Dengel2012_Semantic_Technologies. This concept is not necessarily limited to websites, but can just as well be applied for any data storage. These deliberations waged the establishment of standards for describing meta information, such as:

- Resource Description Framework (see @heading:rdf_standard)
- Web Ontology Language (@heading:owl)
- #todo[List more from the book @Dengel2012_Semantic_Technologies]


== RDF Standard <heading:rdf_standard>
The W3C#sym.trademark.registered recommends a standard for exchange of semantically annotated information called the Resource Description Framework (RDF) standard model. The most notable recommendations are

- the RDF graph format and triples (see @heading:triples),

- the Internationalised Resource Identifier (@heading:iri) and

- the query language SPARQL (see @heading:sparql).

This chapter introduces the parts of the recommendation which are relevant to this work and builds a bridge to concrete conventions around RDF, i.#sym.space.punct\e. Wikibase. 

#todo[
- What are alternatives to RDF databases?
- How do RDF databases work?
- Which query languages work / are used on RDF databases?
]

#todo[
  What is a reifier good for/used for (irl)?
]

#todo[
  Important resource: https://www.mediawiki.org/wiki/Wikibase/Indexing/RDF_Dump_Format#Prefixes_used
]

=== Graphs and Triples <heading:triples>

An *RDF graph* is a set of RDF triples. An RDF triple is said to be asserted in an RDF graph if it is an element of the RDF graph @W3C_RDF_1.2_Proposal.

#definition[
  Let *$I$* denote the set of IRIs (see @heading:iri), *$B$* denote the set containing all blank nodes and *$L$* denote the set of literals (see @heading:literals). Let
  subject $bold("s") in bold("I") union bold("B")$,
  predicate $bold("p") in bold("I")$ and
  object $bold("o") in bold("I") union bold("L") union bold("B")$.

  Then, following @W3C_RDF_1.1_Reference, any three-tuple or triple in an RDF graph is of the form

  $
    (bold("s"), bold("p"), bold("o"))
  $
  #align(center)[or equivalently]
  $ 
    bold("s") xarrow(bold("p")) bold("o"),
  $ <def:spo>
]

if subject *$s$* relates to object *$o$* in a way which the predicate *$p$* describes.

#example[
  Suppose a subject is given the name "Johann Wolfgang von Goethe", which relates to an object of the name "University of Leipzig", in the way, that the subject was a student at the object. Using the formalism from @def:spo, one might be inclined to produce something like:
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

Internationalised Resource Identifiers (IRIs) [#link("https://www.ietf.org/rfc/rfc3987.txt")[RFC3987]] are a superset of Uniform Resource Identifiers (URIs) [#link("https://www.ietf.org/rfc/rfc3986.txt")[RFC3986]]. Their purpose is to *refer to a resource*. The resource an IRI points at is called *referent*. 

The main advantage of IRIs over URIs are their enhanced character set. However, the details are not directly relevant to this work, therefore I will simply refer to the quoted RFCs for further reading.

=== Literals <heading:literals>

The definitions in this section follow the *RDF v1.2* specifications @W3C_RDF_1.2_Proposal, which, at the time of writing, is a working draft. Again, the technical specifications are not directly relevant to the matters of this work, therefore I will abstract from the implementation details. 

#definition[
  A *literal* in an RDF graph can be used to express values such as strings, dates and numbers. It can have two elements:
  + a *lexical form*, which is a Unicode string,
  + a *data type IRI*, which defines the mapping from the lexical form to the literal value in the user representation. (also note the remark below this list)
  + a *language tag*, which allows to add express from which language the *lexical form* stems and
  + a *base direction tag*, which occurs in combination with the *language tag* to indicate the reading direction (left-to-right or right-to-left).

  _Remarks: (1) The necessity of the language and base direction tag are indicated by two separate *special IRIs*. (2) The only difference to RDF v1.1 is, that is does not allow for a base direction tag._ 
] <def:literals>

#definition[
  The *literal value* of a *literal* in an RDF graph is defined in dependence of the fields available in the *literal*. The availability of a tuple entry is characterising for the *literal type*. The literal value is a tuple. #todo[mention, whether this is supported in the implementation]

  #figure(caption: [Mapping from literal to literal value],
  align(center, table(columns: 2, align: horizon,
    [Literal Type], [Literal Value],
    [language-tagged], [(lexical form, language tag)],
    [direction-tagged], [(lexical form, language tag, base direction tag)],
    [has IRI stated in the\ #link("https://www.w3.org/TR/rdf12-concepts/#dfn-recognized-datatype-iri")[list of recognized data type IRIs]], [the literal value interpreted\ as the indicated data type]
  )))
]

=== Blank nodes
RDF specifies *blank nodes*, which do not have an IRI nor a literal assigned to them. The specification @W3C_RDF_1.1_Reference and the current version of its successor @W3C_RDF_1.2_Proposal do not comment on the structure of a blank node: "Otherwise, the set of possible blank nodes is arbitrary." @W3C_RDF_1.1_Reference.
It only specifies, that *the set of blank nodes is disjunct from all literals and IRIs*.
In most common RDF formats, a blank node can be locally referenced using a *local name*.

#figure(caption: [*Turtle syntax*#footnote[https://www.w3.org/TR/turtle/] example showing the use of a *blank node* $bold(b)$. Usually, a blank node is indicated by a _special prefix_, followed by a *local name*. In the case of Turtle, the underline character, followed by a local name, which can essentially be alphanumerical (see @def:prefixes_and_bases for more on prefixes). Example taken from @Dengel2012_Semantic_Technologies.],
```TURTLE
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix carfs: <http://www.carfs-ag.de/Personen#> .
@prefix carfin: <http://www.carfs-ag.de/Finanzen#> .
@prefix ex: <http://www.dfki.de/example/#> .

carfs:baispilov ex:Briefwechsel _:b .
_:b rdf:type rdf:Seq .
_:b rdf:_1 carfin:Anfrage-2010-153 .
_:b rdf:_2 carfin:Anfrage-2010-632 .
_:b rdf:_3 carfin:Anfrage-2010-632b .
```
)

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

This section follows the current standard RDF v1.1 @W3C_SPARQL_Specification.

#blockquote[
  SPARQL can be used to express queries across diverse data sources, whether the data is stored natively as RDF or viewed as RDF via middleware. SPARQL contains capabilities for querying required and optional graph patterns along with their conjunctions and disjunctions. [...] The results of SPARQL queries can be results sets or RDF graphs. @W3C_SPARQL_Specification
]

#todo[what is the sparql *protocol*? and what is an rdf query language?]

==== Syntax
Writing SPARQL queries is pretty straight-forward: The wanted structure
is expressed in terms of the query language, and the unkonwn parts are left out. Say the user wants to know which universities Goethe went to. The matching query would look like @example:goethe_query. The key challenge is to formalise the question. Even this step is difficult for a user
#figure(caption: "Which educational institutions did Goethe visit?",
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
An IRI in SPARQL is indicated by the delimiters `<` and `>` (in that order). According to the documentation
#todo[Keep it brief, but explain.]

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

#todo[
  Which features does SPARQL offer?

  - How does "describe" work? (because it might be interesting as a graph exploring method)

  - Define prefix
]

=== RDF Data Model in Wikibase
*Wikibase* is one of the most widely used softwares for community knowledge bases, with the most prominant instance, *Wikidata*#footnote[http://wikidata.org --- an initiative for a free community knowledge base], storing \~115 million data items. Wikibase instances allow for a mapping from their internal storage to an expression in RDF syntax @wikibase_rdf_mapping_article. (See @fig:rdf_mapping for an impression.) This invertible mapping permits the use of _RDF terminology to refer to structures within Wikibase_. Also relevant to this work are the prefix conventions of Wikibase, which will come to play in @heading:qualifiers.

#remark[This specific data model is interesting, because of its wide use, it defines a de-facto standard in the semantic web community.]

==== Wikibase terminology
A thing is referred to as an *item* and assigned a unique *Q-Number* within a Wikibase instance. Any predicate is called *property* and assigned a unique *P-Number*.

As can be seen in @example:prefixes_in_wikidata, there are many prefixes apparently for the same things, namely *items* and *properties*. However, their use 
in Wikibase depends on the context. @fig:rdf_mapping shows how they come into play in the Wikibase data model. It is important to mention, that once an item 
or property is added to Wikibase, it is referencable using all of the prefixes of the data model.

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

#figure(caption: [An excerpt of customary IRI prefixes defined by Wikidata],
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

#figure(caption: [Informal overview of Wikibase conventions for\ mapping information about an Item to the RDF standard @wikibase_rdf_mapping_graphic],
  image("rdf_mapping.svg", width: 87%)
) <fig:rdf_mapping>

=== Qualifiers <heading:qualifiers>
Most real-world relationships might present to be more complex than something one would want to model in a single triple. For example, one may want to express that "Goethe" was educated at the "University of Leipzig" from 3 October 1765 to 28 August 1768. One possibility is to let relationships have more than two operands, i.e. increase the arity by one for each additional parameter. "Educated at" would then be called "educated at (#sym.dot) from (#sym.dot) to (#sym.dot)". Another way using the limited triple syntax is to create an implicit object, that assists in modelling the relationship. We use it to describe a new concept; a human might be inclined to give it a name, e.g. "educated at for a certain time". The triples exemplify a *qualified statement* as seen in Wikibase instances: #todo[Rework formulation]
$
  "Goethe" &longArrow("educated at") && "Uni Leipzig", \
  "Goethe" &longArrow("educated at") && "Implicit1", \
  "Implicit1" &longArrow("educated at") && "Uni Leipzig", \
  "Implicit1" &longArrow("started at") && 3.10.1765, #<ex_qualifier_1> \
  "Implicit1" &longArrow("ended at") && 28.08.1768.  #<ex_qualifier_2>
$ <assertions_goethe_education>

Having specified such an implicit concept for our concept "educated at for a certain time", one is free to add a few extra statements about what he studied and whether he graduated:

$
  "Implicit1" &longArrow("field of study") && "Law", \
  "Implicit1" &longArrow("graduated") && "True"
$ <assertions_goethe_education_revised>

#definition[
  Let $Sigma$ be a valid alphabet and $Sigma^*$ its Kleene closure. Let
  $f_p, f_q, f_s in I$ be _distinct_ IRI prefixes for *p*\roperties, *q*\ualifiers and property *s*\tatements,
  $s in I$ be a specific subject,#sym.space.med
  $Q:= { f_q u | u in Sigma^*}, Q subset I$ a set of qualifier IRIs with $q_i in Q$,#sym.space.med 
  $P:= { f_p u | u in Sigma^*}, P subset I$ a set of predicate IRIs, with $p in P$,#sym.space.med
  with the limitation $u in Sigma^*$ and $q_1 = f_q u <=> p = f_p u$. Additionally, let 
  $p_s := f_s u <=> p := f_p u$ be the property with a statement prefix,#sym.space.med
  $o in L union I, o_j in O subset.eq L union I$ an arbitrary set of objects and #sym.space.med
  $b in B$ a blank node. #todo[Is this a blank or unnamed node? Look at a dump.]
  Then, a *qualified statement* is defined as a set containing the triples
  $
      {(s,bold(p),o), (s, bold(p), b), (b,p_s,o)} union {(b, q_i, o_i) | i in NN}.
  $
  Statements such as $(b, q_i, o_i)$ are called *qualifiers* and $(s, bold(p), o)$ is called *qualified property*.
] <def:qualifiers>

#remark[
  The term and concept "qualifier" are *not* used or specified in the RDF references @W3C_RDF_1.1_Reference @W3C_RDF_1.2_Proposal.  This definition follows the Wikibase implementation, where the *qualified property* is displayed hierarchically above the qualifiers. The seemingly duplicate assertion $(s,p,o_1)$ is not erroneous, but an implementation detail of Wikibase and simply for convenience. ]

This method of describing information allows us to implicitly define new concepts. Any program dealing with qualifiers merely handles the explicit assertions for an anonymous concept. But, this anonymity poses a challenge to a human interpreter; implicit concepts usually remain unnamed (#todo[below (how does it work)]).

#todo[
  How do qualifiers actually work in the context of the spec @W3C_RDF_1.2_Proposal? Do they use blank nodes?
  - They are not specified by RDF
  - They *probably* use blank nodes. I need to do more research on this.
]

#todo[How do qualifiers get their name in Wikidata?
- Don't understand the question. A qualified statement is specified by the first "qualifier" statement
]

#todo[Are qualifiers specific to an RDF implementation?]


== Visual Query Graph
This chapter mostly follows @Vargas2019_RDF_Explorer. 

#definition[
  A visual query graph (VQG) is defined as a directed, edge- and vertex-labelled graph $G=(N,E)$, with vertices/nodes $N$ and edges $E$. The nodes of $G$ are a finite set of IRIs, literals or variables: $N subset bold("I") union bold("L") union bold("V")$.
  The edges of the VQG are a finite set of triples, where each triple indicated a directed edge between two nodes with a label taken from the set of IRIs or variables: $E subset N times (bold("I") union bold("V")) times N$.
  Note here, that the VQG does not contain blank nodes.
]

Following @Vargas2019_RDF_Explorer, the VQG is _constructed_ using a _visual query language_, consisting of four algebraic operators, which will correspond to atomic user interactions: adding a variable node, adding a literal node and adding a directed edge. In addition, I propose the action of adding and removing an edge qualifier.

#figure(
  table(columns: 2,
    [User Interaction], [Inverse User Action],
    [Adding a variable node], [Removing a node],
    [Adding a literal node], [Removing a node],
    [Adding a directed edge], [Removing a directed edge],
    [*Adding an edge qualifier*], [*Removing an edge qualifier*]
  )
)

#definition[
  A *qualifier* $e_q$ in the visual query graph $G=(N,E)$ is defined as an edge, going *from a qualified edge* $e in E$ to a *qualifying value* $n in N$: $e_q in E_q subset E times (bold("I") union bold("V")) times N$.
]

#remark[
  A *decorated edge* can be looked at as a node.
]

#todo[How would a blank node in a VQG look like?]

#todo[]

== Mapping Visual Query Graphs to SPARQL queries
The VQG allows for arbitrary triple assertions with variables. It does not offer the expression capabilities to apply filters or 

== Linked Open Data <heading:lod>

== Web Ontology Language <heading:owl>
@Sack2009_OWL_und_OWL_Semantik
@Lacy2005_OWL

= Developed Architecture, System Design and Implementation <heading:implementation>

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
+ the _translator from VGQ to SPARQL and vice versa_ (forthon called *backend*).

The most important aspects for the choice of software and UX design were usability and maintability. The aim is to lay the basis for a software, which can be applied in day-to-day as an "almost-no-code" query builder. The development of Query by Graph will be continued in the project _HisQu_ by the #link("https://www.mephisto.uni-jena.de/")[MEPHisto group] funded by #link("https://4memory.de")[NFDI4Memory]. Therefore, the focus lay on building an extensible, future-proof platform, rather than implementing every thought-of feature. Firstly, this stopped me from implementing the ontology integration module. #todo[Explain what the ontology integration module is, if I have enough time.]

== Architecture
Since SPARQL is mostly used in the context of a web browser, the choice for a web app seemed obvious.
Now, the backend had to be watertight regarding explainability and traceability. There are several good choices,
especially functional programming language, but since Rust#footnote[http://www.rust-lang.org] can be compiled to WebAssembly#footnote[http://webassembly.org] and therefore executed natively in a browser, the choice fell well in its favor over a server-client architecture. This combination of architectures proves to be robust, quick and still formally precise.

=== Considerations

- everything that has to do with metadata is handled in the frontend
- this is fine for now, as it uses typescript
- but this could be moved to the rust backend
- this was done to ease the development. 

=== Frontend
The *frontend* was written using Vite (MIT License), Vue3 (MIT License), ReteJS (MIT License) and TailwindCSS (MIT License). Its purpose is to allow 
+ the user to build a VQG,
+ searching for items and properties in arbitrary Wikibase instances and
+ display meta-information on items and properties.

For 

- Web App (Vite+Vue+Rust+ReteJS+TailwindCSS)
- All mapping algorithms are written in Rust to ensure completeness and speed
- Integrates fuzzy search using Wikibase APIs (exemplary implementation for Wikidata and FactGrid)

=== Backend
- mention which tools I used (spargebra)
- and how the algorithm comes to its results


#todo[
The pipeline from VQG to SPARQL query and vice versa needs to be made clear:
- especially comment on optimisations, like when something is semantically equal i do not redraw the VQG
]


== Feature List
#todo[Decide on how detailed do I want this to be.]

== VQG-SPARQL Mapping-Algorithm



Novel to current work:
+ Qualifiers are visualised more intuitively (see Simons Blog @Simons_Blog_Entry_Graphic_query)
+ Multiple data sources and clear prefixes #todo[Check, whether this is actually new]
+ ... more?

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

== SPARQL-OWL Mapping

=== Select Queries
#todo[
  Which features can I graphically visualise?
  - Triples
  - Qualifiers
  - Literals
  - blank nodes?
  - Filters?
  - ...
]

A SPARQL-SELECT-Query

= Measurement results / analysis / discussion

#todo[
- whatever you have done, you must comment it, compare it to other systems, evaluate it
- usually, adequate graphs help to show the benefits of your approach
- caution: each result/graph must be discussed! what’s the reason for this peak or why have you observed this effect
]

== Practical Application
- Patrick Stahl developed for Clemens Beck
- Changes / contributions by patrick are clearly marked in Version Control

#todo[How do I license the code? Maybe Rechtsamt fragen.]

== User Feedback
100% of female users reported that the user interface looked very nice.

= Further Work

+ Creating/Manipulating RDF assertions (INSERT and UPDATE statements)

+ Many language features of SPARQL:
  - FILTER
  - JOIN
  - Aggregate
  - SUBSTR
  - ...

+ Implementing the OWL integration within Query by Graph

+ If an entity in the SPARQL query is selected, also highlight in the retejs editor

+ If the query is changed, try to not move the nodes, but reuse their position.
  - this would involve rewriting the importConnections

+ Formulating queries from natural language using Large Language Models

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
