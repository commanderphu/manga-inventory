const express = require('express');
const mangaRouter = require('./routes/manga');
const cors = require('cors');

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/mangas', mangaRouter);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
