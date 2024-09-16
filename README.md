# TrustIn

Hi and welcome to TrustIn. We are a small company located in Paris. We help financial departments to
assess their suppliers database reliability by performing an evaluation on the supplier's company.

Unfortunately, our evaluations don't hold the same relevance depending on their state. We have a system
in place which lists the state of the evaluations performed for a specific type of company (i.e Siren).

We recently signed up a new client. His database is filled with *Vat companies*.
This requires an update in our system.

**Your task is to add a new feature to our system so that we can evaluate
a new type of company (i.e Vat -tax number-)**.

#### First an introduction to our system
- All evaluations have a type which refers to the company's type
- All evaluations have a state and its reason
- All evaluations have a score: an evaluation doesn't hold the same value according to its state and over time.

#### Rules for Siren evaluation
- When the state is unconfirmed because the api is unreachable:
    - If the current score is equal or greater than 50, the Siren evaluation's score decreases of 5 points;
    - If the current score is lower than 50, the Siren evaluation's score decreases of 1 point;

#### Rules for Vat evaluation
- When the state is unconfirmed because the api is unreachable:
    - If the current score is equal or greater than 50, the Vat evaluation's score decreases of 1 point;
    - If the current score is lower than 50, the Vat evaluation's score decreases of 3 points;

#### Some common rules to both company's types
- A new evaluation is done when:
   - the state is unconfirmed for an ongoing api database update;
   - the current score is equal to 0;
- When the state is unfavorable, the company evaluation's score does not decrease (a closed company will never open again);
- When the state is favorable, the company evaluation's score decreases of 1 point (on the contrary, a company can close so an evaluation should be challenged again after some time);
- The score cannot go below 0;

---

Siren evaluation is based on an external source (opendatasoft) which is already implemented.
Note that an example output of this external source has been provided in the eventually where the opendatasoft API is down,
that is the only use you could have of `siren-example-output.json`.

Here are some real world examples of Siren : `320878499`, `120027016`, `356000000`

For the Vat evaluation, **it is not required** to implement an external source, but to use instead the following as a fake API
that returns randomly a state and a reason:

 ```ruby
      data = [
        { state: "favorable", reason: "company_opened" },
        { state: "unfavorable", reason: "company_closed" },
        { state: "unconfirmed", reason: "unable_to_reach_api" },
        { state: "unconfirmed", reason: "ongoing_database_update" },
      ].sample
      evaluation.state = data[:state]
      evaluation.reason = data[:reason]
      evaluation.score = 100
 ```

Here are some examples of Vat numbers: `IE6388047V`, `LU26375245`, `GB727255821`

---

Feel free to make any changes, reorganise and add any new code / files as long as everything
still works correctly and do not forget to add/rework the specs.

The debrief will be the opportunity to explain your choices and expose possible
enhancements.

Good luck!
