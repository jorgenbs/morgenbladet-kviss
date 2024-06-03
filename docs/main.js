function init() {
  console.log(kviss);
  const el = document.getElementById("kviss");
  const header = document.querySelector("h1");

  header.innerHTML = kviss.quizName;

  kviss.adjacencyPairs.forEach((q) => {
    const question = document.createElement("li");
    const innerList = document.createElement("ul");
    const answer = document.createElement("li");

    question.innerHTML = q.question;
    answer.innerHTML = q.answer;
    answer.style.display = "none";

    question.addEventListener("click", (_) => {
      answer.style.display = "";
    });

    el.appendChild(question);
    question.appendChild(innerList);
    innerList.appendChild(answer);
  });
}
