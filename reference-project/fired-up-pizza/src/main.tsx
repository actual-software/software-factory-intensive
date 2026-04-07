import React from "react";
import ReactDOM from "react-dom/client";

function App() {
  return (
    <div className="min-h-screen bg-orange-50">
      <header className="bg-red-700 text-white p-6">
        <h1 className="text-3xl font-bold">Fired Up Pizza</h1>
        <p className="text-orange-200">Fresh pies, fired up fast</p>
      </header>
      <main className="max-w-4xl mx-auto p-6">
        <p className="text-gray-600">
          Welcome to Fired Up Pizza. The menu is coming soon — this project is
          built by the Software Factory.
        </p>
      </main>
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
