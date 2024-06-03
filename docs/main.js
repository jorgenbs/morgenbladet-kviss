function init() {
  const quiz = kviss[0];
  const el = document.getElementById("kviss");
  const header = document.querySelector("h1");
  header.innerHTML = quiz.quizName;
  quiz.adjacencyPairs.forEach((q) => {
    const li = document.createElement("li");
    li.innerHTML = q.question;
    el.appendChild(li);
  });
}
